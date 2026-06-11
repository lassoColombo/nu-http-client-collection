# Auto-generated client for Service Fabric Client APIs v6.5.0.36
# Source: https://api.apis.guru/v2/specs/azure.com/servicefabric/6.5.0.36/swagger.json
# Auth: --token flag or $env.SERVICE_FABRIC_CLIENT_APIS_TOKEN

const BASE_URL = "http://azure.local:19080"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SERVICE_FABRIC_CLIENT_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["http://azure.local:19080" "https://azure.local:19080"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def api-version-completer [] { ["6.0"] }
def api-version-completer-1 [] { ["6.4"] }
def api-version-completer-2 [] { ["6.2"] }
def api-version-completer-3 [] { ["6.1"] }
def api-version-completer-4 [] { ["6.0-preview"] }
def api-version-completer-5 [] { ["6.4-preview"] }
def api-version-completer-6 [] { ["6.2-preview"] }
def NodeTransitionType-completer [] { ["Invalid" "Start" "Stop"] }
def DataLossMode-completer [] { ["FullDataLoss" "Invalid" "PartialDataLoss"] }
def QuorumLossMode-completer [] { ["AllReplicas" "Invalid" "QuorumReplicas"] }
def RestartPartitionMode-completer [] { ["AllReplicasOrInstances" "Invalid" "OnlyActiveSecondaries"] }
def api-version-completer-7 [] { ["6.5"] }
def api-version-completer-8 [] { ["6.3"] }
def NodeStatusFilter-completer [] { ["all" "default" "disabled" "disabling" "down" "enabling" "removed" "unknown" "up"] }
def ServiceKind-completer [] { ["Stateful" "Stateless"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cancel-repair-task CancelRepairTask" } } | get name | first)
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

# Requests the cancellation of the given repair task.
#
# POST /$/CancelRepairTask
# operationId: CancelRepairTask
export def "cancel-repair-task CancelRepairTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
]: nothing -> record<Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/CancelRepairTask" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new repair task.
#
# POST /$/CreateRepairTask
# operationId: CreateRepairTask
export def "create-repair-task CreateRepairTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
]: nothing -> record<Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/CreateRepairTask" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a completed repair task.
#
# POST /$/DeleteRepairTask
# operationId: DeleteRepairTask
export def "delete-repair-task DeleteRepairTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/DeleteRepairTask" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Forces the approval of the given repair task.
#
# POST /$/ForceApproveRepairTask
# operationId: ForceApproveRepairTask
export def "force-approve-repair-task ForceApproveRepairTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
]: nothing -> record<Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/ForceApproveRepairTask" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the Azure Active Directory metadata used for secured connection to cluster.
#
# GET /$/GetAadMetadata
# operationId: GetAadMetadata
export def "get-aad-metadata GetAadMetadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<metadata: record<authority: string, client: string, cluster: string, login: string, redirect: string, tenant: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetAadMetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the Service Fabric standalone cluster configuration.
#
# GET /$/GetClusterConfiguration
# operationId: GetClusterConfiguration
export def "get-cluster-configuration GetClusterConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ConfigurationApiVersion: string # The API version of the Standalone cluster json configuration.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ClusterConfiguration: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ConfigurationApiVersion" $ConfigurationApiVersion "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterConfiguration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the cluster configuration upgrade status of a Service Fabric standalone cluster.
#
# GET /$/GetClusterConfigurationUpgradeStatus
# operationId: GetClusterConfigurationUpgradeStatus
export def "get-cluster-configuration-upgrade-status GetClusterConfigurationUpgradeStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ConfigVersion: string, Details: string, ProgressStatus: int, UpgradeState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterConfigurationUpgradeStatus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of a Service Fabric cluster.
#
# GET /$/GetClusterHealth
# operationId: GetClusterHealth
export def "get-cluster-health GetClusterHealth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --NodesHealthStateFilter: int # Allows filtering of the node health state objects returned in the result of cluster health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only nodes that match the filter are returned. All nodes are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of nodes with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ApplicationsHealthStateFilter: int # Allows filtering of the application health state objects returned in the result of cluster health query based on their health state. The possible values for this parameter include integer value obtained from members or bitwise operations on members of HealthStateFilter enumeration. Only applications that match the filter are returned. All applications are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of applications with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ExcludeHealthStatistics: string@bool-completer # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --IncludeSystemApplicationHealthStatistics: string@bool-completer # Indicates whether the health statistics should include the fabric:/System application health statistics. False by default. If IncludeSystemApplicationHealthStatistics is set to true, the health statistics include the entities that belong to the fabric:/System application. Otherwise, the query result includes health statistics only for user applications. The health statistics must be included in the query result for this parameter to be applied. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationHealthStates: table<Name: string, AggregatedHealthState: string>, NodeHealthStates: table<Id: record, Name: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "NodesHealthStateFilter" $NodesHealthStateFilter "scalar") (serialize-qp "ApplicationsHealthStateFilter" $ApplicationsHealthStateFilter "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "ExcludeHealthStatistics" $ExcludeHealthStatistics "scalar") (serialize-qp "IncludeSystemApplicationHealthStatistics" $IncludeSystemApplicationHealthStatistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of a Service Fabric cluster using the specified policy.
#
# POST /$/GetClusterHealth
# operationId: GetClusterHealthUsingPolicy
export def "get-cluster-health GetClusterHealthUsingPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --NodesHealthStateFilter: int # Allows filtering of the node health state objects returned in the result of cluster health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only nodes that match the filter are returned. All nodes are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of nodes with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ApplicationsHealthStateFilter: int # Allows filtering of the application health state objects returned in the result of cluster health query based on their health state. The possible values for this parameter include integer value obtained from members or bitwise operations on members of HealthStateFilter enumeration. Only applications that match the filter are returned. All applications are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of applications with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ExcludeHealthStatistics: string@bool-completer # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --IncludeSystemApplicationHealthStatistics: string@bool-completer # Indicates whether the health statistics should include the fabric:/System application health statistics. False by default. If IncludeSystemApplicationHealthStatistics is set to true, the health statistics include the entities that belong to the fabric:/System application. Otherwise, the query result includes health statistics only for user applications. The health statistics must be included in the query result for this parameter to be applied. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationHealthStates: table<Name: string, AggregatedHealthState: string>, NodeHealthStates: table<Id: record, Name: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "NodesHealthStateFilter" $NodesHealthStateFilter "scalar") (serialize-qp "ApplicationsHealthStateFilter" $ApplicationsHealthStateFilter "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "ExcludeHealthStatistics" $ExcludeHealthStatistics "scalar") (serialize-qp "IncludeSystemApplicationHealthStatistics" $IncludeSystemApplicationHealthStatistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of a Service Fabric cluster using health chunks.
#
# GET /$/GetClusterHealthChunk
# operationId: GetClusterHealthChunk
export def "get-cluster-health-chunk GetClusterHealthChunk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationHealthStateChunks: record<Items: list<record>, TotalCount: int>, HealthState: string, NodeHealthStateChunks: record<Items: list<record>, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterHealthChunk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of a Service Fabric cluster using health chunks.
#
# POST /$/GetClusterHealthChunk
# operationId: GetClusterHealthChunkUsingPolicyAndAdvancedFilters
export def "get-cluster-health-chunk GetClusterHealthChunkUsingPolicyAndAdvancedFilters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationHealthStateChunks: record<Items: list<record>, TotalCount: int>, HealthState: string, NodeHealthStateChunks: record<Items: list<record>, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterHealthChunk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the Service Fabric cluster manifest.
#
# GET /$/GetClusterManifest
# operationId: GetClusterManifest
export def "get-cluster-manifest GetClusterManifest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Manifest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterManifest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the current Service Fabric cluster version.
#
# GET /$/GetClusterVersion
# operationId: GetClusterVersion
export def "get-cluster-version GetClusterVersion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetClusterVersion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the load of a Service Fabric cluster.
#
# GET /$/GetLoadInformation
# operationId: GetClusterLoad
export def "get-load-information GetClusterLoad" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<LastBalancingEndTimeUtc: string, LastBalancingStartTimeUtc: string, LoadMetricInformation: table<Action: string, ActivityThreshold: string, BalancingThreshold: string, BufferedClusterCapacityRemaining: string, ClusterBufferedCapacity: string, ClusterCapacity: string, ClusterCapacityRemaining: string, ClusterLoad: string, ClusterRemainingBufferedCapacity: string, ClusterRemainingCapacity: string, CurrentClusterLoad: string, DeviationAfter: string, DeviationBefore: string, IsBalancedAfter: bool, IsBalancedBefore: bool, IsClusterCapacityViolation: bool, MaxNodeLoadNodeId: record, MaxNodeLoadValue: string, MaximumNodeLoad: string, MinNodeLoadNodeId: record, MinNodeLoadValue: string, MinimumNodeLoad: string, Name: string, NodeBufferPercentage: string, PlannedLoadRemoval: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetLoadInformation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of fabric code versions that are provisioned in a Service Fabric cluster.
#
# GET /$/GetProvisionedCodeVersions
# operationId: GetProvisionedFabricCodeVersionInfoList
export def "get-provisioned-code-versions GetProvisionedFabricCodeVersionInfoList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --CodeVersion: string # The product version of Service Fabric.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<CodeVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "CodeVersion" $CodeVersion "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetProvisionedCodeVersions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of fabric config versions that are provisioned in a Service Fabric cluster.
#
# GET /$/GetProvisionedConfigVersions
# operationId: GetProvisionedFabricConfigVersionInfoList
export def "get-provisioned-config-versions GetProvisionedFabricConfigVersionInfoList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ConfigVersion: string # The config version of Service Fabric.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<ConfigVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ConfigVersion" $ConfigVersion "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetProvisionedConfigVersions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of repair tasks matching the given filters.
#
# GET /$/GetRepairTaskList
# operationId: GetRepairTaskList
export def "get-repair-task-list GetRepairTaskList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --TaskIdFilter: string # The repair task ID prefix to be matched.
  --StateFilter: int # A bitwise-OR of the following values, specifying which task states should be included in the result list.  - 1 - Created - 2 - Claimed - 4 - Preparing - 8 - Approved - 16 - Executing - 32 - Restoring - 64 - Completed
  --ExecutorFilter: string # The name of the repair executor whose claimed tasks should be included in the list.
]: nothing -> table<Action: string, Description: string, Executor: string, ExecutorData: string, Flags: int, History: record<ApprovedUtcTimestamp: string, ClaimedUtcTimestamp: string, CompletedUtcTimestamp: string, CreatedUtcTimestamp: string, ExecutingUtcTimestamp: string, PreparingHealthCheckEndUtcTimestamp: string, PreparingHealthCheckStartUtcTimestamp: string, PreparingUtcTimestamp: string, RestoringHealthCheckEndUtcTimestamp: string, RestoringHealthCheckStartUtcTimestamp: string, RestoringUtcTimestamp: string>, Impact: record<Kind: string>, PerformPreparingHealthCheck: bool, PerformRestoringHealthCheck: bool, PreparingHealthCheckState: string, RestoringHealthCheckState: string, ResultCode: int, ResultDetails: string, ResultStatus: string, State: string, Target: record<Kind: string>, TaskId: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "TaskIdFilter" $TaskIdFilter "scalar") (serialize-qp "StateFilter" $StateFilter "scalar") (serialize-qp "ExecutorFilter" $ExecutorFilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetRepairTaskList" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the service state of Service Fabric Upgrade Orchestration Service.
#
# GET /$/GetUpgradeOrchestrationServiceState
# operationId: GetUpgradeOrchestrationServiceState
export def "get-upgrade-orchestration-service-state GetUpgradeOrchestrationServiceState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ServiceState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetUpgradeOrchestrationServiceState" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the progress of the current cluster upgrade.
#
# GET /$/GetUpgradeProgress
# operationId: GetClusterUpgradeProgress
export def "get-upgrade-progress GetClusterUpgradeProgress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<CodeVersion: string, ConfigVersion: string, CurrentUpgradeDomainProgress: record<DomainName: string, NodeUpgradeProgressList: list<record>>, FailureReason: string, FailureTimestampUtc: string, NextUpgradeDomain: string, RollingUpgradeMode: string, StartTimestampUtc: string, UnhealthyEvaluations: table<HealthEvaluation: record>, UpgradeDescription: record<ApplicationHealthPolicyMap: list<record>, ClusterHealthPolicy: record<ApplicationTypeHealthPolicyMap: list, ConsiderWarningAsError: bool, MaxPercentUnhealthyApplications: int, MaxPercentUnhealthyNodes: int>, ClusterUpgradeHealthPolicy: record<MaxPercentDeltaUnhealthyNodes: int, MaxPercentUpgradeDomainDeltaUnhealthyNodes: int>, CodeVersion: string, ConfigVersion: string, EnableDeltaHealthEvaluation: bool, ForceRestart: bool, MonitoringPolicy: record<FailureAction: string, HealthCheckRetryTimeoutInMilliseconds: string, HealthCheckStableDurationInMilliseconds: string, HealthCheckWaitDurationInMilliseconds: string, UpgradeDomainTimeoutInMilliseconds: string, UpgradeTimeoutInMilliseconds: string>, RollingUpgradeMode: string, SortOrder: string, UpgradeKind: string, UpgradeReplicaSetCheckTimeoutInSeconds: int>, UpgradeDomainDurationInMilliseconds: string, UpgradeDomainProgressAtFailure: record<DomainName: string, NodeUpgradeProgressList: list<record>>, UpgradeDomains: table<Name: string, State: string>, UpgradeDurationInMilliseconds: string, UpgradeState: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/GetUpgradeProgress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invokes an administrative command on the given Infrastructure Service instance.
#
# POST /$/InvokeInfrastructureCommand
# operationId: InvokeInfrastructureCommand
export def "invoke-infrastructure-command InvokeInfrastructureCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --Command: string # The text of the command to be invoked. The content of the command is infrastructure-specific.
  --ServiceId: string # The identity of the infrastructure service. This is the full name of the infrastructure service without the 'fabric:' URI scheme. This parameter required only for the cluster that has more than one instance of infrastructure service running.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Command" $Command "scalar") (serialize-qp "ServiceId" $ServiceId "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/InvokeInfrastructureCommand" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invokes a read-only query on the given infrastructure service instance.
#
# GET /$/InvokeInfrastructureQuery
# operationId: InvokeInfrastructureQuery
export def "invoke-infrastructure-query InvokeInfrastructureQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --Command: string # The text of the command to be invoked. The content of the command is infrastructure-specific.
  --ServiceId: string # The identity of the infrastructure service. This is the full name of the infrastructure service without the 'fabric:' URI scheme. This parameter required only for the cluster that has more than one instance of infrastructure service running.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Command" $Command "scalar") (serialize-qp "ServiceId" $ServiceId "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/InvokeInfrastructureQuery" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Make the cluster upgrade move on to the next upgrade domain.
#
# POST /$/MoveToNextUpgradeDomain
# operationId: ResumeClusterUpgrade
export def "move-to-next-upgrade-domain ResumeClusterUpgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/MoveToNextUpgradeDomain" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provision the code or configuration packages of a Service Fabric cluster.
#
# POST /$/Provision
# operationId: ProvisionCluster
export def "provision ProvisionCluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/Provision" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Indicates to the Service Fabric cluster that it should attempt to recover any services (including system services) which are currently stuck in quorum loss.
#
# POST /$/RecoverAllPartitions
# operationId: RecoverAllPartitions
export def "recover-all-partitions RecoverAllPartitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/RecoverAllPartitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Indicates to the Service Fabric cluster that it should attempt to recover the system services that are currently stuck in quorum loss.
#
# POST /$/RecoverSystemPartitions
# operationId: RecoverSystemPartitions
export def "recover-system-partitions RecoverSystemPartitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/RecoverSystemPartitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends a health report on the Service Fabric cluster.
#
# POST /$/ReportClusterHealth
# operationId: ReportClusterHealth
export def "report-cluster-health ReportClusterHealth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --Immediate: string@bool-completer # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $Immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/ReportClusterHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Roll back the upgrade of a Service Fabric cluster.
#
# POST /$/RollbackUpgrade
# operationId: RollbackClusterUpgrade
export def "rollback-upgrade RollbackClusterUpgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/RollbackUpgrade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the service state of Service Fabric Upgrade Orchestration Service.
#
# POST /$/SetUpgradeOrchestrationServiceState
# operationId: SetUpgradeOrchestrationServiceState
export def "set-upgrade-orchestration-service-state SetUpgradeOrchestrationServiceState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<CurrentCodeVersion: string, CurrentManifestVersion: string, PendingUpgradeType: string, TargetCodeVersion: string, TargetManifestVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/SetUpgradeOrchestrationServiceState" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start upgrading the configuration of a Service Fabric standalone cluster.
#
# POST /$/StartClusterConfigurationUpgrade
# operationId: StartClusterConfigurationUpgrade
export def "start-cluster-configuration-upgrade StartClusterConfigurationUpgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/StartClusterConfigurationUpgrade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Changes the verbosity of service placement health reporting.
#
# POST /$/ToggleVerboseServicePlacementHealthReporting
# operationId: ToggleVerboseServicePlacementHealthReporting
export def "toggle-verbose-service-placement-health-reporting ToggleVerboseServicePlacementHealthReporting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --Enabled: string@bool-completer # The verbosity of service placement health reporting.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Enabled" $Enabled "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/ToggleVerboseServicePlacementHealthReporting" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unprovision the code or configuration packages of a Service Fabric cluster.
#
# POST /$/Unprovision
# operationId: UnprovisionCluster
export def "unprovision UnprovisionCluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/Unprovision" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the execution state of a repair task.
#
# POST /$/UpdateRepairExecutionState
# operationId: UpdateRepairExecutionState
export def "update-repair-execution-state UpdateRepairExecutionState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
]: nothing -> record<Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/UpdateRepairExecutionState" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the health policy of the given repair task.
#
# POST /$/UpdateRepairTaskHealthPolicy
# operationId: UpdateRepairTaskHealthPolicy
export def "update-repair-task-health-policy UpdateRepairTaskHealthPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
]: nothing -> record<Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/UpdateRepairTaskHealthPolicy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the upgrade parameters of a Service Fabric cluster upgrade.
#
# POST /$/UpdateUpgrade
# operationId: UpdateClusterUpgrade
export def "update-upgrade UpdateClusterUpgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/UpdateUpgrade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start upgrading the code or configuration version of a Service Fabric cluster.
#
# POST /$/Upgrade
# operationId: StartClusterUpgrade
export def "upgrade StartClusterUpgrade" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/$/Upgrade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of application types in the Service Fabric cluster.
#
# GET /ApplicationTypes
# operationId: GetApplicationTypeInfoList
export def "application-types GetApplicationTypeInfoList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ApplicationTypeDefinitionKindFilter: int # Used to filter on ApplicationTypeDefinitionKind which is the mechanism used to define a Service Fabric application type. - Default - Default value, which performs the same function as selecting "All". The value is 0. - All - Filter that matches input with any ApplicationTypeDefinitionKind value. The value is 65535. - ServiceFabricApplicationPackage - Filter that matches input with ApplicationTypeDefinitionKind value ServiceFabricApplicationPackage. The value is 1. - Compose - Filter that matches input with ApplicationTypeDefinitionKind value Compose. The value is 2. (default: 0)
  --ExcludeApplicationParameters: string@bool-completer # The flag that specifies whether application parameters will be excluded from the result. (default: false)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationTypeDefinitionKind: string, DefaultParameterList: list, Name: string, Status: string, StatusDetails: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationTypeDefinitionKindFilter" $ApplicationTypeDefinitionKindFilter "scalar") (serialize-qp "ExcludeApplicationParameters" $ExcludeApplicationParameters "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ApplicationTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provisions or registers a Service Fabric application type with the cluster using the '.sfpkg' package in the external store or using the application package in the image store.
#
# POST /ApplicationTypes/$/Provision
# operationId: ProvisionApplicationType
export def "application-types-provision ProvisionApplicationType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ApplicationTypes/$/Provision" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of application types in the Service Fabric cluster matching exactly the specified name.
#
# GET /ApplicationTypes/{applicationTypeName}
# operationId: GetApplicationTypeInfoListByName
export def "application-types GetApplicationTypeInfoListByName" [
  applicationTypeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ApplicationTypeVersion: string # The version of the application type.
  --ExcludeApplicationParameters: string@bool-completer # The flag that specifies whether application parameters will be excluded from the result. (default: false)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationTypeDefinitionKind: string, DefaultParameterList: list, Name: string, Status: string, StatusDetails: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationTypeVersion" $ApplicationTypeVersion "scalar") (serialize-qp "ExcludeApplicationParameters" $ExcludeApplicationParameters "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ApplicationTypes/($applicationTypeName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the manifest describing an application type.
#
# GET /ApplicationTypes/{applicationTypeName}/$/GetApplicationManifest
# operationId: GetApplicationManifest
export def "application-types-get-application-manifest GetApplicationManifest" [
  applicationTypeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ApplicationTypeVersion: string # The version of the application type.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Manifest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationTypeVersion" $ApplicationTypeVersion "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ApplicationTypes/($applicationTypeName)/$/GetApplicationManifest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the manifest describing a service type.
#
# GET /ApplicationTypes/{applicationTypeName}/$/GetServiceManifest
# operationId: GetServiceManifest
export def "application-types-get-service-manifest GetServiceManifest" [
  applicationTypeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ApplicationTypeVersion: string # The version of the application type.
  --ServiceManifestName: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Manifest: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationTypeVersion" $ApplicationTypeVersion "scalar") (serialize-qp "ServiceManifestName" $ServiceManifestName "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ApplicationTypes/($applicationTypeName)/$/GetServiceManifest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list containing the information about service types that are supported by a provisioned application type in a Service Fabric cluster.
#
# GET /ApplicationTypes/{applicationTypeName}/$/GetServiceTypes
# operationId: GetServiceTypeInfoList
export def "application-types-get-service-types GetServiceTypeInfoList" [
  applicationTypeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ApplicationTypeVersion: string # The version of the application type.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<IsServiceGroup: bool, ServiceManifestName: string, ServiceManifestVersion: string, ServiceTypeDescription: record<Extensions: list, IsStateful: bool, Kind: string, LoadMetrics: list, PlacementConstraints: string, ServicePlacementPolicies: list, ServiceTypeName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationTypeVersion" $ApplicationTypeVersion "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ApplicationTypes/($applicationTypeName)/$/GetServiceTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about a specific service type that is supported by a provisioned application type in a Service Fabric cluster.
#
# GET /ApplicationTypes/{applicationTypeName}/$/GetServiceTypes/{serviceTypeName}
# operationId: GetServiceTypeInfoByName
export def "application-types-get-service-types GetServiceTypeInfoByName" [
  applicationTypeName: string
  serviceTypeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ApplicationTypeVersion: string # The version of the application type.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<IsServiceGroup: bool, ServiceManifestName: string, ServiceManifestVersion: string, ServiceTypeDescription: record<Extensions: list<record>, IsStateful: bool, Kind: string, LoadMetrics: list<record>, PlacementConstraints: string, ServicePlacementPolicies: list<record>, ServiceTypeName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationTypeVersion" $ApplicationTypeVersion "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ApplicationTypes/($applicationTypeName)/$/GetServiceTypes/($serviceTypeName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes or unregisters a Service Fabric application type from the cluster.
#
# POST /ApplicationTypes/{applicationTypeName}/$/Unprovision
# operationId: UnprovisionApplicationType
export def "application-types-unprovision UnprovisionApplicationType" [
  applicationTypeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ApplicationTypes/($applicationTypeName)/$/Unprovision" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of applications created in the Service Fabric cluster that match the specified filters.
#
# GET /Applications
# operationId: GetApplicationInfoList
export def "applications GetApplicationInfoList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-3 # The version of the API. This parameter is required and its value must be '6.1'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.1)
  --ApplicationDefinitionKindFilter: int # Used to filter on ApplicationDefinitionKind, which is the mechanism used to define a Service Fabric application. - Default - Default value, which performs the same function as selecting "All". The value is 0. - All - Filter that matches input with any ApplicationDefinitionKind value. The value is 65535. - ServiceFabricApplicationDescription - Filter that matches input with ApplicationDefinitionKind value ServiceFabricApplicationDescription. The value is 1. - Compose - Filter that matches input with ApplicationDefinitionKind value Compose. The value is 2. (default: 0)
  --ApplicationTypeName: string # The application type name used to filter the applications to query for. This value should not contain the application type version.
  --ExcludeApplicationParameters: string@bool-completer # The flag that specifies whether application parameters will be excluded from the result. (default: false)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationDefinitionKind: string, HealthState: string, Id: string, Name: string, Parameters: list, Status: string, TypeName: string, TypeVersion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ApplicationDefinitionKindFilter" $ApplicationDefinitionKindFilter "scalar") (serialize-qp "ApplicationTypeName" $ApplicationTypeName "scalar") (serialize-qp "ExcludeApplicationParameters" $ExcludeApplicationParameters "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a Service Fabric application.
#
# POST /Applications/$/Create
# operationId: CreateApplication
export def "applications-create CreateApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Applications/$/Create" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a Service Fabric application.
#
# GET /Applications/{applicationId}
# operationId: GetApplicationInfo
export def "applications GetApplicationInfo" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ExcludeApplicationParameters: string@bool-completer # The flag that specifies whether application parameters will be excluded from the result. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationDefinitionKind: string, HealthState: string, Id: string, Name: string, Parameters: table<Key: string, Value: string>, Status: string, TypeName: string, TypeVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ExcludeApplicationParameters" $ExcludeApplicationParameters "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes an existing Service Fabric application.
#
# POST /Applications/{applicationId}/$/Delete
# operationId: DeleteApplication
export def "applications-delete DeleteApplication" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ForceRemove: string@bool-completer # Remove a Service Fabric application or service forcefully without going through the graceful shutdown sequence. This parameter can be used to forcefully delete an application or service for which delete is timing out due to issues in the service code that prevents graceful close of replicas.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ForceRemove" $ForceRemove "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/Delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disables periodic backup of Service Fabric application.
#
# POST /Applications/{applicationId}/$/DisableBackup
# operationId: DisableApplicationBackup
export def "applications-disable-backup DisableApplicationBackup" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/DisableBackup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enables periodic backup of stateful partitions under this Service Fabric application.
#
# POST /Applications/{applicationId}/$/EnableBackup
# operationId: EnableApplicationBackup
export def "applications-enable-backup EnableApplicationBackup" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/EnableBackup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the Service Fabric application backup configuration information.
#
# GET /Applications/{applicationId}/$/GetBackupConfigurationInfo
# operationId: GetApplicationBackupConfigurationInfo
export def "applications-get-backup-configuration-info GetApplicationBackupConfigurationInfo" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<Kind: string, PolicyInheritedFrom: string, PolicyName: string, SuspensionInfo: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/GetBackupConfigurationInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of backups available for every partition in this application.
#
# GET /Applications/{applicationId}/$/GetBackups
# operationId: GetApplicationBackupList
export def "applications-get-backups GetApplicationBackupList" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --Latest: string@bool-completer # Specifies whether to get only the most recent backup available for a partition for the specified time range. (default: false)
  --StartDateTimeFilter: string # Specify the start date time from which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, all backups from the beginning are enumerated. (format: date-time)
  --EndDateTimeFilter: string # Specify the end date time till which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, enumeration is done till the most recent backup. (format: date-time)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "Latest" $Latest "scalar") (serialize-qp "StartDateTimeFilter" $StartDateTimeFilter "scalar") (serialize-qp "EndDateTimeFilter" $EndDateTimeFilter "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/GetBackups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of the service fabric application.
#
# GET /Applications/{applicationId}/$/GetHealth
# operationId: GetApplicationHealth
export def "applications-get-health GetApplicationHealth" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --DeployedApplicationsHealthStateFilter: int # Allows filtering of the deployed applications health state objects returned in the result of application health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only deployed applications that match the filter will be returned. All deployed applications are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of deployed applications with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ServicesHealthStateFilter: int # Allows filtering of the services health state objects returned in the result of services health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only services that match the filter are returned. All services are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of services with HealthState value of OK (2) and Warning (4) will be returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ExcludeHealthStatistics: string@bool-completer # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<DeployedApplicationHealthStates: table<ApplicationName: string, NodeName: string, AggregatedHealthState: string>, Name: string, ServiceHealthStates: table<ServiceName: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "DeployedApplicationsHealthStateFilter" $DeployedApplicationsHealthStateFilter "scalar") (serialize-qp "ServicesHealthStateFilter" $ServicesHealthStateFilter "scalar") (serialize-qp "ExcludeHealthStatistics" $ExcludeHealthStatistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of a Service Fabric application using the specified policy.
#
# POST /Applications/{applicationId}/$/GetHealth
# operationId: GetApplicationHealthUsingPolicy
export def "applications-get-health GetApplicationHealthUsingPolicy" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --DeployedApplicationsHealthStateFilter: int # Allows filtering of the deployed applications health state objects returned in the result of application health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only deployed applications that match the filter will be returned. All deployed applications are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of deployed applications with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ServicesHealthStateFilter: int # Allows filtering of the services health state objects returned in the result of services health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only services that match the filter are returned. All services are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of services with HealthState value of OK (2) and Warning (4) will be returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ExcludeHealthStatistics: string@bool-completer # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<DeployedApplicationHealthStates: table<ApplicationName: string, NodeName: string, AggregatedHealthState: string>, Name: string, ServiceHealthStates: table<ServiceName: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "DeployedApplicationsHealthStateFilter" $DeployedApplicationsHealthStateFilter "scalar") (serialize-qp "ServicesHealthStateFilter" $ServicesHealthStateFilter "scalar") (serialize-qp "ExcludeHealthStatistics" $ExcludeHealthStatistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets load information about a Service Fabric application.
#
# GET /Applications/{applicationId}/$/GetLoadInformation
# operationId: GetApplicationLoadInfo
export def "applications-get-load-information GetApplicationLoadInfo" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationLoadMetricInformation: table<MaximumCapacity: int, Name: string, ReservationCapacity: int, TotalApplicationCapacity: int>, Id: string, MaximumNodes: int, MinimumNodes: int, NodeCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/GetLoadInformation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about all services belonging to the application specified by the application ID.
#
# GET /Applications/{applicationId}/$/GetServices
# operationId: GetServiceInfoList
export def "applications-get-services GetServiceInfoList" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ServiceTypeName: string # The service type name used to filter the services to query for.
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<HealthState: string, Id: string, IsServiceGroup: bool, ManifestVersion: string, Name: string, ServiceKind: string, ServiceStatus: string, TypeName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ServiceTypeName" $ServiceTypeName "scalar") (serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/GetServices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates the specified Service Fabric service.
#
# POST /Applications/{applicationId}/$/GetServices/$/Create
# operationId: CreateService
export def "applications-get-services-create CreateService" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/GetServices/$/Create" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a Service Fabric service from the service template.
#
# POST /Applications/{applicationId}/$/GetServices/$/CreateFromTemplate
# operationId: CreateServiceFromTemplate
export def "applications-get-services-create-from-template CreateServiceFromTemplate" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/GetServices/$/CreateFromTemplate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about the specific service belonging to the Service Fabric application.
#
# GET /Applications/{applicationId}/$/GetServices/{serviceId}
# operationId: GetServiceInfo
export def "applications-get-services GetServiceInfo" [
  applicationId: string
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<HealthState: string, Id: string, IsServiceGroup: bool, ManifestVersion: string, Name: string, ServiceKind: string, ServiceStatus: string, TypeName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/GetServices/($serviceId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets details for the latest upgrade performed on this application.
#
# GET /Applications/{applicationId}/$/GetUpgradeProgress
# operationId: GetApplicationUpgrade
export def "applications-get-upgrade-progress GetApplicationUpgrade" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<CurrentUpgradeDomainProgress: record<DomainName: string, NodeUpgradeProgressList: list<record>>, FailureReason: string, FailureTimestampUtc: string, Name: string, NextUpgradeDomain: string, RollingUpgradeMode: string, StartTimestampUtc: string, TargetApplicationTypeVersion: string, TypeName: string, UnhealthyEvaluations: table<HealthEvaluation: record>, UpgradeDescription: record<ApplicationHealthPolicy: record<ConsiderWarningAsError: bool, DefaultServiceTypeHealthPolicy: record, MaxPercentUnhealthyDeployedApplications: int, ServiceTypeHealthPolicyMap: list>, ForceRestart: bool, MonitoringPolicy: record<FailureAction: string, HealthCheckRetryTimeoutInMilliseconds: string, HealthCheckStableDurationInMilliseconds: string, HealthCheckWaitDurationInMilliseconds: string, UpgradeDomainTimeoutInMilliseconds: string, UpgradeTimeoutInMilliseconds: string>, Name: string, Parameters: list<record>, RollingUpgradeMode: string, SortOrder: string, TargetApplicationTypeVersion: string, UpgradeKind: string, UpgradeReplicaSetCheckTimeoutInSeconds: int>, UpgradeDomainDurationInMilliseconds: string, UpgradeDomainProgressAtFailure: record<DomainName: string, NodeUpgradeProgressList: list<record>>, UpgradeDomains: table<Name: string, State: string>, UpgradeDurationInMilliseconds: string, UpgradeState: string, UpgradeStatusDetails: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/GetUpgradeProgress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resumes upgrading an application in the Service Fabric cluster.
#
# POST /Applications/{applicationId}/$/MoveToNextUpgradeDomain
# operationId: ResumeApplicationUpgrade
export def "applications-move-to-next-upgrade-domain ResumeApplicationUpgrade" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/MoveToNextUpgradeDomain" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends a health report on the Service Fabric application.
#
# POST /Applications/{applicationId}/$/ReportHealth
# operationId: ReportApplicationHealth
export def "applications-report-health ReportApplicationHealth" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --Immediate: string@bool-completer # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $Immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/ReportHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resumes periodic backup of a Service Fabric application which was previously suspended.
#
# POST /Applications/{applicationId}/$/ResumeBackup
# operationId: ResumeApplicationBackup
export def "applications-resume-backup ResumeApplicationBackup" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/ResumeBackup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts rolling back the currently on-going upgrade of an application in the Service Fabric cluster.
#
# POST /Applications/{applicationId}/$/RollbackUpgrade
# operationId: RollbackApplicationUpgrade
export def "applications-rollback-upgrade RollbackApplicationUpgrade" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/RollbackUpgrade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suspends periodic backup for the specified Service Fabric application.
#
# POST /Applications/{applicationId}/$/SuspendBackup
# operationId: SuspendApplicationBackup
export def "applications-suspend-backup SuspendApplicationBackup" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/SuspendBackup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an ongoing application upgrade in the Service Fabric cluster.
#
# POST /Applications/{applicationId}/$/UpdateUpgrade
# operationId: UpdateApplicationUpgrade
export def "applications-update-upgrade UpdateApplicationUpgrade" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/UpdateUpgrade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts upgrading an application in the Service Fabric cluster.
#
# POST /Applications/{applicationId}/$/Upgrade
# operationId: StartApplicationUpgrade
export def "applications-upgrade StartApplicationUpgrade" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Applications/($applicationId)/$/Upgrade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of backups available for the specified backed up entity at the specified backup location.
#
# POST /BackupRestore/$/GetBackups
# operationId: GetBackupsFromBackupLocation
export def "backup-restore-get-backups GetBackupsFromBackupLocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BackupRestore/$/GetBackups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all the backup policies configured.
#
# GET /BackupRestore/BackupPolicies
# operationId: GetBackupPolicyList
export def "backup-restore-backup-policies GetBackupPolicyList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<AutoRestoreOnDataLoss: bool, MaxIncrementalBackups: int, Name: string, RetentionPolicy: record, Schedule: record, Storage: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BackupRestore/BackupPolicies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a backup policy.
#
# POST /BackupRestore/BackupPolicies/$/Create
# operationId: CreateBackupPolicy
export def "backup-restore-backup-policies-create CreateBackupPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BackupRestore/BackupPolicies/$/Create" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a particular backup policy by name.
#
# GET /BackupRestore/BackupPolicies/{backupPolicyName}
# operationId: GetBackupPolicyByName
export def "backup-restore-backup-policies GetBackupPolicyByName" [
  backupPolicyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<AutoRestoreOnDataLoss: bool, MaxIncrementalBackups: int, Name: string, RetentionPolicy: record<RetentionPolicyType: string>, Schedule: record<ScheduleKind: string>, Storage: record<FriendlyName: string, StorageKind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/BackupRestore/BackupPolicies/($backupPolicyName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the backup policy.
#
# POST /BackupRestore/BackupPolicies/{backupPolicyName}/$/Delete
# operationId: DeleteBackupPolicy
export def "backup-restore-backup-policies-delete DeleteBackupPolicy" [
  backupPolicyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/BackupRestore/BackupPolicies/($backupPolicyName)/$/Delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of backup entities that are associated with this policy.
#
# GET /BackupRestore/BackupPolicies/{backupPolicyName}/$/GetBackupEnabledEntities
# operationId: GetAllEntitiesBackedUpByPolicy
export def "backup-restore-backup-policies-get-backup-enabled-entities GetAllEntitiesBackedUpByPolicy" [
  backupPolicyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<EntityKind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/BackupRestore/BackupPolicies/($backupPolicyName)/$/GetBackupEnabledEntities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the backup policy.
#
# POST /BackupRestore/BackupPolicies/{backupPolicyName}/$/Update
# operationId: UpdateBackupPolicy
export def "backup-restore-backup-policies-update UpdateBackupPolicy" [
  backupPolicyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/BackupRestore/BackupPolicies/($backupPolicyName)/$/Update" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of compose deployments created in the Service Fabric cluster.
#
# GET /ComposeDeployments
# operationId: GetComposeDeploymentStatusList
export def "compose-deployments GetComposeDeploymentStatusList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (default: 6.0-preview)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationName: string, Name: string, Status: string, StatusDetails: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ComposeDeployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a Service Fabric compose deployment.
#
# PUT /ComposeDeployments/$/Create
# operationId: CreateComposeDeployment
export def "compose-deployments-create CreateComposeDeployment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ComposeDeployments/$/Create" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information about a Service Fabric compose deployment.
#
# GET /ComposeDeployments/{deploymentName}
# operationId: GetComposeDeploymentStatus
export def "compose-deployments GetComposeDeploymentStatus" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationName: string, Name: string, Status: string, StatusDetails: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ComposeDeployments/($deploymentName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes an existing Service Fabric compose deployment from cluster.
#
# POST /ComposeDeployments/{deploymentName}/$/Delete
# operationId: RemoveComposeDeployment
export def "compose-deployments-delete RemoveComposeDeployment" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ComposeDeployments/($deploymentName)/$/Delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets details for the latest upgrade performed on this Service Fabric compose deployment.
#
# GET /ComposeDeployments/{deploymentName}/$/GetUpgradeProgress
# operationId: GetComposeDeploymentUpgradeProgress
export def "compose-deployments-get-upgrade-progress GetComposeDeploymentUpgradeProgress" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationHealthPolicy: record<ConsiderWarningAsError: bool, DefaultServiceTypeHealthPolicy: record<MaxPercentUnhealthyPartitionsPerService: int, MaxPercentUnhealthyReplicasPerPartition: int, MaxPercentUnhealthyServices: int>, MaxPercentUnhealthyDeployedApplications: int, ServiceTypeHealthPolicyMap: list<record>>, ApplicationName: string, ApplicationUnhealthyEvaluations: table<HealthEvaluation: record>, ApplicationUpgradeStatusDetails: string, CurrentUpgradeDomainDuration: string, CurrentUpgradeDomainProgress: record<DomainName: string, NodeUpgradeProgressList: list<record>>, DeploymentName: string, FailureReason: string, FailureTimestampUtc: string, ForceRestart: bool, MonitoringPolicy: record<FailureAction: string, HealthCheckRetryTimeoutInMilliseconds: string, HealthCheckStableDurationInMilliseconds: string, HealthCheckWaitDurationInMilliseconds: string, UpgradeDomainTimeoutInMilliseconds: string, UpgradeTimeoutInMilliseconds: string>, RollingUpgradeMode: string, StartTimestampUtc: string, TargetApplicationTypeVersion: string, UpgradeDomainProgressAtFailure: record<DomainName: string, NodeUpgradeProgressList: list<record>>, UpgradeDuration: string, UpgradeKind: string, UpgradeReplicaSetCheckTimeoutInSeconds: int, UpgradeState: string, UpgradeStatusDetails: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ComposeDeployments/($deploymentName)/$/GetUpgradeProgress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts rolling back a compose deployment upgrade in the Service Fabric cluster.
#
# POST /ComposeDeployments/{deploymentName}/$/RollbackUpgrade
# operationId: StartRollbackComposeDeploymentUpgrade
export def "compose-deployments-rollback-upgrade StartRollbackComposeDeploymentUpgrade" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ComposeDeployments/($deploymentName)/$/RollbackUpgrade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts upgrading a compose deployment in the Service Fabric cluster.
#
# POST /ComposeDeployments/{deploymentName}/$/Upgrade
# operationId: StartComposeDeploymentUpgrade
export def "compose-deployments-upgrade StartComposeDeploymentUpgrade" [
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-4 # The version of the API. This parameter is required and its value must be '"6.0-preview'. (default: 6.0-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ComposeDeployments/($deploymentName)/$/Upgrade" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all Applications-related events.
#
# GET /EventsStore/Applications/Events
# operationId: GetApplicationsEventList
export def "events-store-applications-events GetApplicationsEventList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --StartTimeUtc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EndTimeUtc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EventsTypesFilter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --ExcludeAnalysisEvents: string@bool-completer # This param disables the retrieval of AnalysisEvents if true is passed.
  --SkipCorrelationLookup: string@bool-completer # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<ApplicationId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "EventsTypesFilter" $EventsTypesFilter "scalar") (serialize-qp "ExcludeAnalysisEvents" $ExcludeAnalysisEvents "scalar") (serialize-qp "SkipCorrelationLookup" $SkipCorrelationLookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EventsStore/Applications/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets an Application-related events.
#
# GET /EventsStore/Applications/{applicationId}/$/Events
# operationId: GetApplicationEventList
export def "events-store-applications-events GetApplicationEventList" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --StartTimeUtc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EndTimeUtc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EventsTypesFilter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --ExcludeAnalysisEvents: string@bool-completer # This param disables the retrieval of AnalysisEvents if true is passed.
  --SkipCorrelationLookup: string@bool-completer # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<ApplicationId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "EventsTypesFilter" $EventsTypesFilter "scalar") (serialize-qp "ExcludeAnalysisEvents" $ExcludeAnalysisEvents "scalar") (serialize-qp "SkipCorrelationLookup" $SkipCorrelationLookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/EventsStore/Applications/($applicationId)/$/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all Cluster-related events.
#
# GET /EventsStore/Cluster/Events
# operationId: GetClusterEventList
export def "events-store-cluster-events GetClusterEventList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --StartTimeUtc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EndTimeUtc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EventsTypesFilter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --ExcludeAnalysisEvents: string@bool-completer # This param disables the retrieval of AnalysisEvents if true is passed.
  --SkipCorrelationLookup: string@bool-completer # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "EventsTypesFilter" $EventsTypesFilter "scalar") (serialize-qp "ExcludeAnalysisEvents" $ExcludeAnalysisEvents "scalar") (serialize-qp "SkipCorrelationLookup" $SkipCorrelationLookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EventsStore/Cluster/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all Containers-related events.
#
# GET /EventsStore/Containers/Events
# operationId: GetContainersEventList
export def "events-store-containers-events GetContainersEventList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-6 # The version of the API. This parameter is required and its value must be '6.2-preview'. (default: 6.2-preview)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --StartTimeUtc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EndTimeUtc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EventsTypesFilter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --ExcludeAnalysisEvents: string@bool-completer # This param disables the retrieval of AnalysisEvents if true is passed.
  --SkipCorrelationLookup: string@bool-completer # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "EventsTypesFilter" $EventsTypesFilter "scalar") (serialize-qp "ExcludeAnalysisEvents" $ExcludeAnalysisEvents "scalar") (serialize-qp "SkipCorrelationLookup" $SkipCorrelationLookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EventsStore/Containers/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all correlated events for a given event.
#
# GET /EventsStore/CorrelatedEvents/{eventInstanceId}/$/Events
# operationId: GetCorrelatedEventList
export def "events-store-correlated-events-events GetCorrelatedEventList" [
  eventInstanceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/EventsStore/CorrelatedEvents/($eventInstanceId)/$/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all Nodes-related Events.
#
# GET /EventsStore/Nodes/Events
# operationId: GetNodesEventList
export def "events-store-nodes-events GetNodesEventList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --StartTimeUtc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EndTimeUtc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EventsTypesFilter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --ExcludeAnalysisEvents: string@bool-completer # This param disables the retrieval of AnalysisEvents if true is passed.
  --SkipCorrelationLookup: string@bool-completer # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<NodeName: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "EventsTypesFilter" $EventsTypesFilter "scalar") (serialize-qp "ExcludeAnalysisEvents" $ExcludeAnalysisEvents "scalar") (serialize-qp "SkipCorrelationLookup" $SkipCorrelationLookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EventsStore/Nodes/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a Node-related events.
#
# GET /EventsStore/Nodes/{nodeName}/$/Events
# operationId: GetNodeEventList
export def "events-store-nodes-events GetNodeEventList" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --StartTimeUtc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EndTimeUtc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EventsTypesFilter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --ExcludeAnalysisEvents: string@bool-completer # This param disables the retrieval of AnalysisEvents if true is passed.
  --SkipCorrelationLookup: string@bool-completer # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<NodeName: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "EventsTypesFilter" $EventsTypesFilter "scalar") (serialize-qp "ExcludeAnalysisEvents" $ExcludeAnalysisEvents "scalar") (serialize-qp "SkipCorrelationLookup" $SkipCorrelationLookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/EventsStore/Nodes/($nodeName)/$/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all Partitions-related events.
#
# GET /EventsStore/Partitions/Events
# operationId: GetPartitionsEventList
export def "events-store-partitions-events GetPartitionsEventList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --StartTimeUtc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EndTimeUtc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EventsTypesFilter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --ExcludeAnalysisEvents: string@bool-completer # This param disables the retrieval of AnalysisEvents if true is passed.
  --SkipCorrelationLookup: string@bool-completer # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<PartitionId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "EventsTypesFilter" $EventsTypesFilter "scalar") (serialize-qp "ExcludeAnalysisEvents" $ExcludeAnalysisEvents "scalar") (serialize-qp "SkipCorrelationLookup" $SkipCorrelationLookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EventsStore/Partitions/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a Partition-related events.
#
# GET /EventsStore/Partitions/{partitionId}/$/Events
# operationId: GetPartitionEventList
export def "events-store-partitions-events GetPartitionEventList" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --StartTimeUtc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EndTimeUtc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EventsTypesFilter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --ExcludeAnalysisEvents: string@bool-completer # This param disables the retrieval of AnalysisEvents if true is passed.
  --SkipCorrelationLookup: string@bool-completer # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<PartitionId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "EventsTypesFilter" $EventsTypesFilter "scalar") (serialize-qp "ExcludeAnalysisEvents" $ExcludeAnalysisEvents "scalar") (serialize-qp "SkipCorrelationLookup" $SkipCorrelationLookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/EventsStore/Partitions/($partitionId)/$/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all Replicas-related events for a Partition.
#
# GET /EventsStore/Partitions/{partitionId}/$/Replicas/Events
# operationId: GetPartitionReplicasEventList
export def "events-store-partitions-replicas-events GetPartitionReplicasEventList" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --StartTimeUtc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EndTimeUtc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EventsTypesFilter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --ExcludeAnalysisEvents: string@bool-completer # This param disables the retrieval of AnalysisEvents if true is passed.
  --SkipCorrelationLookup: string@bool-completer # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<PartitionId: string, ReplicaId: int, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "EventsTypesFilter" $EventsTypesFilter "scalar") (serialize-qp "ExcludeAnalysisEvents" $ExcludeAnalysisEvents "scalar") (serialize-qp "SkipCorrelationLookup" $SkipCorrelationLookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/EventsStore/Partitions/($partitionId)/$/Replicas/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a Partition Replica-related events.
#
# GET /EventsStore/Partitions/{partitionId}/$/Replicas/{replicaId}/$/Events
# operationId: GetPartitionReplicaEventList
export def "events-store-partitions-replicas-events GetPartitionReplicaEventList" [
  partitionId: string
  replicaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --StartTimeUtc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EndTimeUtc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EventsTypesFilter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --ExcludeAnalysisEvents: string@bool-completer # This param disables the retrieval of AnalysisEvents if true is passed.
  --SkipCorrelationLookup: string@bool-completer # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<PartitionId: string, ReplicaId: int, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "EventsTypesFilter" $EventsTypesFilter "scalar") (serialize-qp "ExcludeAnalysisEvents" $ExcludeAnalysisEvents "scalar") (serialize-qp "SkipCorrelationLookup" $SkipCorrelationLookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/EventsStore/Partitions/($partitionId)/$/Replicas/($replicaId)/$/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets all Services-related events.
#
# GET /EventsStore/Services/Events
# operationId: GetServicesEventList
export def "events-store-services-events GetServicesEventList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --StartTimeUtc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EndTimeUtc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EventsTypesFilter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --ExcludeAnalysisEvents: string@bool-completer # This param disables the retrieval of AnalysisEvents if true is passed.
  --SkipCorrelationLookup: string@bool-completer # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<ServiceId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "EventsTypesFilter" $EventsTypesFilter "scalar") (serialize-qp "ExcludeAnalysisEvents" $ExcludeAnalysisEvents "scalar") (serialize-qp "SkipCorrelationLookup" $SkipCorrelationLookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/EventsStore/Services/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a Service-related events.
#
# GET /EventsStore/Services/{serviceId}/$/Events
# operationId: GetServiceEventList
export def "events-store-services-events GetServiceEventList" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --StartTimeUtc: string # The start time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EndTimeUtc: string # The end time of a lookup query in ISO UTC yyyy-MM-ddTHH:mm:ssZ.
  --EventsTypesFilter: string # This is a comma separated string specifying the types of FabricEvents that should only be included in the response.
  --ExcludeAnalysisEvents: string@bool-completer # This param disables the retrieval of AnalysisEvents if true is passed.
  --SkipCorrelationLookup: string@bool-completer # This param disables the search of CorrelatedEvents information if true is passed. otherwise the CorrelationEvents get processed and HasCorrelatedEvents field in every FabricEvent gets populated.
]: nothing -> table<ServiceId: string, Category: string, EventInstanceId: string, HasCorrelatedEvents: bool, Kind: string, TimeStamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "EventsTypesFilter" $EventsTypesFilter "scalar") (serialize-qp "ExcludeAnalysisEvents" $ExcludeAnalysisEvents "scalar") (serialize-qp "SkipCorrelationLookup" $SkipCorrelationLookup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/EventsStore/Services/($serviceId)/$/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of user-induced fault operations filtered by provided input.
#
# GET /Faults/
# operationId: GetFaultOperationList
export def "faults GetFaultOperationList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --TypeFilter: int # Used to filter on OperationType for user-induced operations.  - 65535 - select all - 1 - select PartitionDataLoss. - 2 - select PartitionQuorumLoss. - 4 - select PartitionRestart. - 8 - select NodeTransition. (default: 65535)
  --StateFilter: int # Used to filter on OperationState's for user-induced operations.  - 65535 - select All - 1 - select Running - 2 - select RollingBack - 8 - select Completed - 16 - select Faulted - 32 - select Cancelled - 64 - select ForceCancelled (default: 65535)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<OperationId: string, State: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "TypeFilter" $TypeFilter "scalar") (serialize-qp "StateFilter" $StateFilter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Faults/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancels a user-induced fault operation.
#
# POST /Faults/$/Cancel
# operationId: CancelOperation
export def "faults-cancel CancelOperation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --OperationId: string # A GUID that identifies a call of this API.  This is passed into the corresponding GetProgress API (format: uuid)
  --Force: string@bool-completer # Indicates whether to gracefully roll back and clean up internal system state modified by executing the user-induced operation. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $OperationId "scalar") (serialize-qp "Force" $Force "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Faults/$/Cancel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the progress of an operation started using StartNodeTransition.
#
# GET /Faults/Nodes/{nodeName}/$/GetTransitionProgress
# operationId: GetNodeTransitionProgress
export def "faults-nodes-get-transition-progress GetNodeTransitionProgress" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --OperationId: string # A GUID that identifies a call of this API.  This is passed into the corresponding GetProgress API (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<NodeTransitionResult: record<ErrorCode: int, NodeResult: record<NodeInstanceId: string, NodeName: string>>, State: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $OperationId "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Faults/Nodes/($nodeName)/$/GetTransitionProgress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts or stops a cluster node.
#
# POST /Faults/Nodes/{nodeName}/$/StartTransition/
# operationId: StartNodeTransition
export def "faults-nodes-start-transition StartNodeTransition" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --OperationId: string # A GUID that identifies a call of this API.  This is passed into the corresponding GetProgress API (format: uuid)
  --NodeTransitionType: string@NodeTransitionType-completer # Indicates the type of transition to perform.  NodeTransitionType.Start will start a stopped node.  NodeTransitionType.Stop will stop a node that is up.
  --NodeInstanceId: string # The node instance ID of the target node.  This can be determined through GetNodeInfo API.
  --StopDurationInSeconds: int # The duration, in seconds, to keep the node stopped.  The minimum value is 600, the maximum is 14400.  After this time expires, the node will automatically come back up. (format: int32)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $OperationId "scalar") (serialize-qp "NodeTransitionType" $NodeTransitionType "scalar") (serialize-qp "NodeInstanceId" $NodeInstanceId "scalar") (serialize-qp "StopDurationInSeconds" $StopDurationInSeconds "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Faults/Nodes/($nodeName)/$/StartTransition/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the progress of a partition data loss operation started using the StartDataLoss API.
#
# GET /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/GetDataLossProgress
# operationId: GetDataLossProgress
export def "faults-services-get-partitions-get-data-loss-progress GetDataLossProgress" [
  serviceId: string
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --OperationId: string # A GUID that identifies a call of this API.  This is passed into the corresponding GetProgress API (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<InvokeDataLossResult: record<ErrorCode: int, SelectedPartition: record<PartitionId: string, ServiceName: string>>, State: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $OperationId "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Faults/Services/($serviceId)/$/GetPartitions/($partitionId)/$/GetDataLossProgress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the progress of a quorum loss operation on a partition started using the StartQuorumLoss API.
#
# GET /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/GetQuorumLossProgress
# operationId: GetQuorumLossProgress
export def "faults-services-get-partitions-get-quorum-loss-progress GetQuorumLossProgress" [
  serviceId: string
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --OperationId: string # A GUID that identifies a call of this API.  This is passed into the corresponding GetProgress API (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<InvokeQuorumLossResult: record<ErrorCode: int, SelectedPartition: record<PartitionId: string, ServiceName: string>>, State: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $OperationId "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Faults/Services/($serviceId)/$/GetPartitions/($partitionId)/$/GetQuorumLossProgress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the progress of a PartitionRestart operation started using StartPartitionRestart.
#
# GET /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/GetRestartProgress
# operationId: GetPartitionRestartProgress
export def "faults-services-get-partitions-get-restart-progress GetPartitionRestartProgress" [
  serviceId: string
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --OperationId: string # A GUID that identifies a call of this API.  This is passed into the corresponding GetProgress API (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<RestartPartitionResult: record<ErrorCode: int, SelectedPartition: record<PartitionId: string, ServiceName: string>>, State: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $OperationId "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Faults/Services/($serviceId)/$/GetPartitions/($partitionId)/$/GetRestartProgress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This API will induce data loss for the specified partition. It will trigger a call to the OnDataLossAsync API of the partition.
#
# POST /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/StartDataLoss
# operationId: StartDataLoss
export def "faults-services-get-partitions-start-data-loss StartDataLoss" [
  serviceId: string
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --OperationId: string # A GUID that identifies a call of this API.  This is passed into the corresponding GetProgress API (format: uuid)
  --DataLossMode: string@DataLossMode-completer # This enum is passed to the StartDataLoss API to indicate what type of data loss to induce.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $OperationId "scalar") (serialize-qp "DataLossMode" $DataLossMode "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Faults/Services/($serviceId)/$/GetPartitions/($partitionId)/$/StartDataLoss" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Induces quorum loss for a given stateful service partition.
#
# POST /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/StartQuorumLoss
# operationId: StartQuorumLoss
export def "faults-services-get-partitions-start-quorum-loss StartQuorumLoss" [
  serviceId: string
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --OperationId: string # A GUID that identifies a call of this API.  This is passed into the corresponding GetProgress API (format: uuid)
  --QuorumLossMode: string@QuorumLossMode-completer # This enum is passed to the StartQuorumLoss API to indicate what type of quorum loss to induce.
  --QuorumLossDuration: int # The amount of time for which the partition will be kept in quorum loss.  This must be specified in seconds.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $OperationId "scalar") (serialize-qp "QuorumLossMode" $QuorumLossMode "scalar") (serialize-qp "QuorumLossDuration" $QuorumLossDuration "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Faults/Services/($serviceId)/$/GetPartitions/($partitionId)/$/StartQuorumLoss" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This API will restart some or all replicas or instances of the specified partition.
#
# POST /Faults/Services/{serviceId}/$/GetPartitions/{partitionId}/$/StartRestart
# operationId: StartPartitionRestart
export def "faults-services-get-partitions-start-restart StartPartitionRestart" [
  serviceId: string
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --OperationId: string # A GUID that identifies a call of this API.  This is passed into the corresponding GetProgress API (format: uuid)
  --RestartPartitionMode: string@RestartPartitionMode-completer # Describe which partitions to restart.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "OperationId" $OperationId "scalar") (serialize-qp "RestartPartitionMode" $RestartPartitionMode "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Faults/Services/($serviceId)/$/GetPartitions/($partitionId)/$/StartRestart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the content information at the root of the image store.
#
# GET /ImageStore
# operationId: GetImageStoreRootContent
export def "image-store GetImageStoreRootContent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<StoreFiles: table<FileSize: string, FileVersion: record, ModifiedDate: string, StoreRelativePath: string>, StoreFolders: table<FileCount: string, StoreRelativePath: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ImageStore" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Commit an image store upload session.
#
# POST /ImageStore/$/CommitUploadSession
# operationId: CommitImageStoreUploadSession
export def "image-store-commit-upload-session CommitImageStoreUploadSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --session-id: string # A GUID generated by the user for a file uploading. It identifies an image store upload session which keeps track of all file chunks until it is committed. (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "session-id" $session_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ImageStore/$/CommitUploadSession" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Copies image store content internally
#
# POST /ImageStore/$/Copy
# operationId: CopyImageStoreContent
export def "image-store-copy CopyImageStoreContent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ImageStore/$/Copy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancels an image store upload session.
#
# DELETE /ImageStore/$/DeleteUploadSession
# operationId: DeleteImageStoreUploadSession
export def "image-store-delete-upload-session DeleteImageStoreUploadSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --session-id: string # A GUID generated by the user for a file uploading. It identifies an image store upload session which keeps track of all file chunks until it is committed. (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "session-id" $session_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ImageStore/$/DeleteUploadSession" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the folder size at the root of the image store.
#
# GET /ImageStore/$/FolderSize
# operationId: GetImageStoreRootFolderSize
export def "image-store-folder-size GetImageStoreRootFolderSize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-7 # The version of the API. This parameter is required and its value must be '6.5'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.5)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<FolderSize: string, StoreRelativePath: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ImageStore/$/FolderSize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the image store upload session by ID.
#
# GET /ImageStore/$/GetUploadSession
# operationId: GetImageStoreUploadSessionById
export def "image-store-get-upload-session GetImageStoreUploadSessionById" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --session-id: string # A GUID generated by the user for a file uploading. It identifies an image store upload session which keeps track of all file chunks until it is committed. (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<UploadSessions: table<ExpectedRanges: list, FileSize: string, ModifiedDate: string, SessionId: string, StoreRelativePath: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "session-id" $session_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ImageStore/$/GetUploadSession" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes existing image store content.
#
# DELETE /ImageStore/{contentPath}
# operationId: DeleteImageStoreContent
export def "image-store DeleteImageStoreContent" [
  contentPath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ImageStore/($contentPath)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the image store content information.
#
# GET /ImageStore/{contentPath}
# operationId: GetImageStoreContent
export def "image-store GetImageStoreContent" [
  contentPath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<StoreFiles: table<FileSize: string, FileVersion: record, ModifiedDate: string, StoreRelativePath: string>, StoreFolders: table<FileCount: string, StoreRelativePath: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ImageStore/($contentPath)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Uploads contents of the file to the image store.
#
# PUT /ImageStore/{contentPath}
# operationId: UploadFile
export def "image-store UploadFile" [
  contentPath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ImageStore/($contentPath)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the size of a folder in image store
#
# GET /ImageStore/{contentPath}/$/FolderSize
# operationId: GetImageStoreFolderSize
export def "image-store-folder-size GetImageStoreFolderSize" [
  contentPath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-7 # The version of the API. This parameter is required and its value must be '6.5'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.5)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<FolderSize: string, StoreRelativePath: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ImageStore/($contentPath)/$/FolderSize" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the image store upload session by relative path.
#
# GET /ImageStore/{contentPath}/$/GetUploadSession
# operationId: GetImageStoreUploadSessionByPath
export def "image-store-get-upload-session GetImageStoreUploadSessionByPath" [
  contentPath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<UploadSessions: table<ExpectedRanges: list, FileSize: string, ModifiedDate: string, SessionId: string, StoreRelativePath: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ImageStore/($contentPath)/$/GetUploadSession" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Uploads a file chunk to the image store relative path.
#
# PUT /ImageStore/{contentPath}/$/UploadChunk
# operationId: UploadFileChunk
export def "image-store-upload-chunk UploadFileChunk" [
  contentPath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --session-id: string # A GUID generated by the user for a file uploading. It identifies an image store upload session which keeps track of all file chunks until it is committed. (format: uuid)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --Content-Range: string # When uploading file chunks to the image store, the Content-Range header field need to be configured and sent with a request. The format should looks like "bytes {First-Byte-Position}-{Last-Byte-Position}/{File-Length}". For example, Content-Range:bytes 300-5000/20000 indicates that user is sending bytes 300 through 5,000 and the total file length is 20,000 bytes.
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "session-id" $session_id "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/ImageStore/($contentPath)/$/UploadChunk" $qp)
  let extra_headers = {"Content-Range": $Content_Range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a Service Fabric name.
#
# POST /Names/$/Create
# operationId: CreateName
export def "names-create CreateName" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Names/$/Create" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a Service Fabric name.
#
# DELETE /Names/{nameId}
# operationId: DeleteName
export def "names DeleteName" [
  nameId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Names/($nameId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns whether the Service Fabric name exists.
#
# GET /Names/{nameId}
# operationId: GetNameExistsInfo
export def "names GetNameExistsInfo" [
  nameId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Names/($nameId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets information on all Service Fabric properties under a given name.
#
# GET /Names/{nameId}/$/GetProperties
# operationId: GetPropertyInfoList
export def "names-get-properties GetPropertyInfoList" [
  nameId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --IncludeValues: string@bool-completer # Allows specifying whether to include the values of the properties returned. True if values should be returned with the metadata; False to return only property metadata. (default: false)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, IsConsistent: bool, Properties: table<Metadata: record, Name: string, Value: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "IncludeValues" $IncludeValues "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Names/($nameId)/$/GetProperties" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submits a property batch.
#
# POST /Names/{nameId}/$/GetProperties/$/SubmitBatch
# operationId: SubmitPropertyBatch
export def "names-get-properties-submit-batch SubmitPropertyBatch" [
  nameId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Properties: any, Kind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Names/($nameId)/$/GetProperties/$/SubmitBatch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the specified Service Fabric property.
#
# DELETE /Names/{nameId}/$/GetProperty
# operationId: DeleteProperty
export def "names-get-property DeleteProperty" [
  nameId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --PropertyName: string # Specifies the name of the property to get.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "PropertyName" $PropertyName "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Names/($nameId)/$/GetProperty" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the specified Service Fabric property.
#
# GET /Names/{nameId}/$/GetProperty
# operationId: GetPropertyInfo
export def "names-get-property GetPropertyInfo" [
  nameId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --PropertyName: string # Specifies the name of the property to get.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Metadata: record<CustomTypeId: string, LastModifiedUtcTimestamp: string, Parent: string, SequenceNumber: string, SizeInBytes: int, TypeId: string>, Name: string, Value: record<Kind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "PropertyName" $PropertyName "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Names/($nameId)/$/GetProperty" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates or updates a Service Fabric property.
#
# PUT /Names/{nameId}/$/GetProperty
# operationId: PutProperty
export def "names-get-property PutProperty" [
  nameId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Names/($nameId)/$/GetProperty" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enumerates all the Service Fabric names under a given name.
#
# GET /Names/{nameId}/$/GetSubNames
# operationId: GetSubNameInfoList
export def "names-get-sub-names GetSubNameInfoList" [
  nameId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --Recursive: string@bool-completer # Allows specifying that the search performed should be recursive. (default: false)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, IsConsistent: bool, SubNames: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Recursive" $Recursive "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Names/($nameId)/$/GetSubNames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of nodes in the Service Fabric cluster.
#
# GET /Nodes
# operationId: GetNodeInfoList
export def "nodes GetNodeInfoList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-8 # The version of the API. This parameter is required and its value must be '6.3'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.3)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --NodeStatusFilter: string@NodeStatusFilter-completer # Allows filtering the nodes based on the NodeStatus. Only the nodes that are matching the specified filter value will be returned. The filter value can be one of the following. (default: default)
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<CodeVersion: string, ConfigVersion: string, FaultDomain: string, HealthState: string, Id: record, InstanceId: string, IpAddressOrFQDN: string, IsSeedNode: bool, IsStopped: bool, Name: string, NodeDeactivationInfo: record, NodeDownAt: string, NodeDownTimeInSeconds: string, NodeStatus: string, NodeUpAt: string, NodeUpTimeInSeconds: string, Type: string, UpgradeDomain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "NodeStatusFilter" $NodeStatusFilter "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Nodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about a specific node in the Service Fabric cluster.
#
# GET /Nodes/{nodeName}
# operationId: GetNodeInfo
export def "nodes GetNodeInfo" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<CodeVersion: string, ConfigVersion: string, FaultDomain: string, HealthState: string, Id: record<Id: string>, InstanceId: string, IpAddressOrFQDN: string, IsSeedNode: bool, IsStopped: bool, Name: string, NodeDeactivationInfo: record<NodeDeactivationIntent: string, NodeDeactivationStatus: string, NodeDeactivationTask: list<record>, PendingSafetyChecks: list<record>>, NodeDownAt: string, NodeDownTimeInSeconds: string, NodeStatus: string, NodeUpAt: string, NodeUpTimeInSeconds: string, Type: string, UpgradeDomain: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Activate a Service Fabric cluster node that is currently deactivated.
#
# POST /Nodes/{nodeName}/$/Activate
# operationId: EnableNode
export def "nodes-activate EnableNode" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/Activate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate a Service Fabric cluster node with the specified deactivation intent.
#
# POST /Nodes/{nodeName}/$/Deactivate
# operationId: DisableNode
export def "nodes-deactivate DisableNode" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/Deactivate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Downloads all of the code packages associated with specified service manifest on the specified node.
#
# POST /Nodes/{nodeName}/$/DeployServicePackage
# operationId: DeployServicePackageToNode
export def "nodes-deploy-service-package DeployServicePackageToNode" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/DeployServicePackage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of applications deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications
# operationId: GetDeployedApplicationInfoList
export def "nodes-get-applications GetDeployedApplicationInfoList" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-3 # The version of the API. This parameter is required and its value must be '6.1'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.1)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --IncludeHealthState: string@bool-completer # Include the health state of an entity. If this parameter is false or not specified, then the health state returned is "Unknown". When set to true, the query goes in parallel to the node and the health system service before the results are merged. As a result, the query is more expensive and may take a longer time. (default: false)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
]: nothing -> record<ContinuationToken: string, Items: table<HealthState: string, Id: string, LogDirectory: string, Name: string, Status: string, TempDirectory: string, TypeName: string, WorkDirectory: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "IncludeHealthState" $IncludeHealthState "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about an application deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}
# operationId: GetDeployedApplicationInfo
export def "nodes-get-applications GetDeployedApplicationInfo" [
  nodeName: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-3 # The version of the API. This parameter is required and its value must be '6.1'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.1)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --IncludeHealthState: string@bool-completer # Include the health state of an entity. If this parameter is false or not specified, then the health state returned is "Unknown". When set to true, the query goes in parallel to the node and the health system service before the results are merged. As a result, the query is more expensive and may take a longer time. (default: false)
]: nothing -> record<HealthState: string, Id: string, LogDirectory: string, Name: string, Status: string, TempDirectory: string, TypeName: string, WorkDirectory: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "IncludeHealthState" $IncludeHealthState "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of code packages deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages
# operationId: GetDeployedCodePackageInfoList
export def "nodes-get-applications-get-code-packages GetDeployedCodePackageInfoList" [
  nodeName: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ServiceManifestName: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster.
  --CodePackageName: string # The name of code package specified in service manifest registered as part of an application type in a Service Fabric cluster.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<HostIsolationMode: string, HostType: string, MainEntryPoint: record<CodePackageEntryPointStatistics: record, EntryPointLocation: string, InstanceId: string, NextActivationTime: string, ProcessId: string, RunAsUserName: string, Status: string>, Name: string, RunFrequencyInterval: string, ServiceManifestName: string, ServicePackageActivationId: string, SetupEntryPoint: record<CodePackageEntryPointStatistics: record, EntryPointLocation: string, InstanceId: string, NextActivationTime: string, ProcessId: string, RunAsUserName: string, Status: string>, Status: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ServiceManifestName" $ServiceManifestName "scalar") (serialize-qp "CodePackageName" $CodePackageName "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetCodePackages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Invoke container API on a container deployed on a Service Fabric node.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages/$/ContainerApi
# operationId: InvokeContainerApi
export def "nodes-get-applications-get-code-packages-container-api InvokeContainerApi" [
  nodeName: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --ServiceManifestName: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster.
  --CodePackageName: string # The name of code package specified in service manifest registered as part of an application type in a Service Fabric cluster.
  --CodePackageInstanceId: string # ID that uniquely identifies a code package instance deployed on a service fabric node.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContainerApiResult: record<Body: string, Content_Encoding: string, Content_Type: string, Status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ServiceManifestName" $ServiceManifestName "scalar") (serialize-qp "CodePackageName" $CodePackageName "scalar") (serialize-qp "CodePackageInstanceId" $CodePackageInstanceId "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetCodePackages/$/ContainerApi" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the container logs for container deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages/$/ContainerLogs
# operationId: GetContainerLogsDeployedOnNode
export def "nodes-get-applications-get-code-packages-container-logs GetContainerLogsDeployedOnNode" [
  nodeName: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --ServiceManifestName: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster.
  --CodePackageName: string # The name of code package specified in service manifest registered as part of an application type in a Service Fabric cluster.
  --Tail: string # Number of lines to show from the end of the logs. Default is 100. 'all' to show the complete logs.
  --Previous: string@bool-completer # Specifies whether to get container logs from exited/dead containers of the code package instance. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ServiceManifestName" $ServiceManifestName "scalar") (serialize-qp "CodePackageName" $CodePackageName "scalar") (serialize-qp "Tail" $Tail "scalar") (serialize-qp "Previous" $Previous "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetCodePackages/$/ContainerLogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restarts a code package deployed on a Service Fabric node in a cluster.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetCodePackages/$/Restart
# operationId: RestartDeployedCodePackage
export def "nodes-get-applications-get-code-packages-restart RestartDeployedCodePackage" [
  nodeName: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetCodePackages/$/Restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about health of an application deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetHealth
# operationId: GetDeployedApplicationHealth
export def "nodes-get-applications-get-health GetDeployedApplicationHealth" [
  nodeName: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --DeployedServicePackagesHealthStateFilter: int # Allows filtering of the deployed service package health state objects returned in the result of deployed application health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only deployed service packages that match the filter are returned. All deployed service packages are used to evaluate the aggregated health state of the deployed application. If not specified, all entries are returned. The state values are flag-based enumeration, so the value can be a combination of these values, obtained using the bitwise 'OR' operator. For example, if the provided value is 6 then health state of service packages with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ExcludeHealthStatistics: string@bool-completer # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<DeployedServicePackageHealthStates: table<ApplicationName: string, NodeName: string, ServiceManifestName: string, ServicePackageActivationId: string, AggregatedHealthState: string>, Name: string, NodeName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "DeployedServicePackagesHealthStateFilter" $DeployedServicePackagesHealthStateFilter "scalar") (serialize-qp "ExcludeHealthStatistics" $ExcludeHealthStatistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about health of an application deployed on a Service Fabric node. using the specified policy.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetHealth
# operationId: GetDeployedApplicationHealthUsingPolicy
export def "nodes-get-applications-get-health GetDeployedApplicationHealthUsingPolicy" [
  nodeName: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --DeployedServicePackagesHealthStateFilter: int # Allows filtering of the deployed service package health state objects returned in the result of deployed application health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only deployed service packages that match the filter are returned. All deployed service packages are used to evaluate the aggregated health state of the deployed application. If not specified, all entries are returned. The state values are flag-based enumeration, so the value can be a combination of these values, obtained using the bitwise 'OR' operator. For example, if the provided value is 6 then health state of service packages with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ExcludeHealthStatistics: string@bool-completer # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<DeployedServicePackageHealthStates: table<ApplicationName: string, NodeName: string, ServiceManifestName: string, ServicePackageActivationId: string, AggregatedHealthState: string>, Name: string, NodeName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "DeployedServicePackagesHealthStateFilter" $DeployedServicePackagesHealthStateFilter "scalar") (serialize-qp "ExcludeHealthStatistics" $ExcludeHealthStatistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of replicas deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetReplicas
# operationId: GetDeployedServiceReplicaInfoList
export def "nodes-get-applications-get-replicas GetDeployedServiceReplicaInfoList" [
  nodeName: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --PartitionId: string # The identity of the partition. (format: uuid)
  --ServiceManifestName: string # The name of a service manifest registered as part of an application type in a Service Fabric cluster.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<Address: string, CodePackageName: string, HostProcessId: string, PartitionId: string, ReplicaStatus: string, ServiceKind: string, ServiceManifestName: string, ServiceName: string, ServicePackageActivationId: string, ServiceTypeName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "PartitionId" $PartitionId "scalar") (serialize-qp "ServiceManifestName" $ServiceManifestName "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetReplicas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of service packages deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages
# operationId: GetDeployedServicePackageInfoList
export def "nodes-get-applications-get-service-packages GetDeployedServicePackageInfoList" [
  nodeName: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<Name: string, ServicePackageActivationId: string, Status: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetServicePackages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of service packages deployed on a Service Fabric node matching exactly the specified name.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}
# operationId: GetDeployedServicePackageInfoListByName
export def "nodes-get-applications-get-service-packages GetDeployedServicePackageInfoListByName" [
  nodeName: string
  applicationId: string
  servicePackageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<Name: string, ServicePackageActivationId: string, Status: string, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetServicePackages/($servicePackageName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about health of a service package for a specific application deployed for a Service Fabric node and application.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}/$/GetHealth
# operationId: GetDeployedServicePackageHealth
export def "nodes-get-applications-get-service-packages-get-health GetDeployedServicePackageHealth" [
  nodeName: string
  applicationId: string
  servicePackageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationName: string, NodeName: string, ServiceManifestName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetServicePackages/($servicePackageName)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about health of service package for a specific application deployed on a Service Fabric node using the specified policy.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}/$/GetHealth
# operationId: GetDeployedServicePackageHealthUsingPolicy
export def "nodes-get-applications-get-service-packages-get-health GetDeployedServicePackageHealthUsingPolicy" [
  nodeName: string
  applicationId: string
  servicePackageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationName: string, NodeName: string, ServiceManifestName: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetServicePackages/($servicePackageName)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends a health report on the Service Fabric deployed service package.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServicePackages/{servicePackageName}/$/ReportHealth
# operationId: ReportDeployedServicePackageHealth
export def "nodes-get-applications-get-service-packages-report-health ReportDeployedServicePackageHealth" [
  nodeName: string
  applicationId: string
  servicePackageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --Immediate: string@bool-completer # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $Immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetServicePackages/($servicePackageName)/$/ReportHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list containing the information about service types from the applications deployed on a node in a Service Fabric cluster.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServiceTypes
# operationId: GetDeployedServiceTypeInfoList
export def "nodes-get-applications-get-service-types GetDeployedServiceTypeInfoList" [
  nodeName: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ServiceManifestName: string # The name of the service manifest to filter the list of deployed service type information. If specified, the response will only contain the information about service types that are defined in this service manifest.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<CodePackageName: string, ServiceManifestName: string, ServicePackageActivationId: string, ServiceTypeName: string, Status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ServiceManifestName" $ServiceManifestName "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetServiceTypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about a specified service type of the application deployed on a node in a Service Fabric cluster.
#
# GET /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/GetServiceTypes/{serviceTypeName}
# operationId: GetDeployedServiceTypeInfoByName
export def "nodes-get-applications-get-service-types GetDeployedServiceTypeInfoByName" [
  nodeName: string
  applicationId: string
  serviceTypeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ServiceManifestName: string # The name of the service manifest to filter the list of deployed service type information. If specified, the response will only contain the information about service types that are defined in this service manifest.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> table<CodePackageName: string, ServiceManifestName: string, ServicePackageActivationId: string, ServiceTypeName: string, Status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ServiceManifestName" $ServiceManifestName "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/GetServiceTypes/($serviceTypeName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends a health report on the Service Fabric application deployed on a Service Fabric node.
#
# POST /Nodes/{nodeName}/$/GetApplications/{applicationId}/$/ReportHealth
# operationId: ReportDeployedApplicationHealth
export def "nodes-get-applications-report-health ReportDeployedApplicationHealth" [
  nodeName: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --Immediate: string@bool-completer # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $Immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetApplications/($applicationId)/$/ReportHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetHealth
# operationId: GetNodeHealth
export def "nodes-get-health GetNodeHealth" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Name: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of a Service Fabric node, by using the specified health policy.
#
# POST /Nodes/{nodeName}/$/GetHealth
# operationId: GetNodeHealthUsingPolicy
export def "nodes-get-health GetNodeHealthUsingPolicy" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Name: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the load information of a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetLoadInformation
# operationId: GetNodeLoadInfo
export def "nodes-get-load-information GetNodeLoadInfo" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<NodeLoadMetricInformation: table<BufferedNodeCapacityRemaining: string, CurrentNodeLoad: string, IsCapacityViolation: bool, Name: string, NodeBufferedCapacity: string, NodeCapacity: string, NodeCapacityRemaining: string, NodeLoad: string, NodeRemainingBufferedCapacity: string, NodeRemainingCapacity: string, PlannedNodeLoadRemoval: string>, NodeName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetLoadInformation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the details of replica deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas
# operationId: GetDeployedServiceReplicaDetailInfoByPartitionId
export def "nodes-get-partitions-get-replicas GetDeployedServiceReplicaDetailInfoByPartitionId" [
  nodeName: string
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<CurrentServiceOperation: string, CurrentServiceOperationStartTimeUtc: string, PartitionId: string, ReportedLoad: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: int>, ServiceKind: string, ServiceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetPartitions/($partitionId)/$/GetReplicas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes a service replica running on a node.
#
# POST /Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas/{replicaId}/$/Delete
# operationId: RemoveReplica
export def "nodes-get-partitions-get-replicas-delete RemoveReplica" [
  nodeName: string
  partitionId: string
  replicaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ForceRemove: string@bool-completer # Remove a Service Fabric application or service forcefully without going through the graceful shutdown sequence. This parameter can be used to forcefully delete an application or service for which delete is timing out due to issues in the service code that prevents graceful close of replicas.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ForceRemove" $ForceRemove "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetPartitions/($partitionId)/$/GetReplicas/($replicaId)/$/Delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the details of replica deployed on a Service Fabric node.
#
# GET /Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas/{replicaId}/$/GetDetail
# operationId: GetDeployedServiceReplicaDetailInfo
export def "nodes-get-partitions-get-replicas-get-detail GetDeployedServiceReplicaDetailInfo" [
  nodeName: string
  partitionId: string
  replicaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<CurrentServiceOperation: string, CurrentServiceOperationStartTimeUtc: string, PartitionId: string, ReportedLoad: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: int>, ServiceKind: string, ServiceName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetPartitions/($partitionId)/$/GetReplicas/($replicaId)/$/GetDetail" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restarts a service replica of a persisted service running on a node.
#
# POST /Nodes/{nodeName}/$/GetPartitions/{partitionId}/$/GetReplicas/{replicaId}/$/Restart
# operationId: RestartReplica
export def "nodes-get-partitions-get-replicas-restart RestartReplica" [
  nodeName: string
  partitionId: string
  replicaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/GetPartitions/($partitionId)/$/GetReplicas/($replicaId)/$/Restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Notifies Service Fabric that the persisted state on a node has been permanently removed or lost.
#
# POST /Nodes/{nodeName}/$/RemoveNodeState
# operationId: RemoveNodeState
export def "nodes-remove-node-state RemoveNodeState" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/RemoveNodeState" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends a health report on the Service Fabric node.
#
# POST /Nodes/{nodeName}/$/ReportHealth
# operationId: ReportNodeHealth
export def "nodes-report-health ReportNodeHealth" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --Immediate: string@bool-completer # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $Immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/ReportHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Restarts a Service Fabric cluster node.
#
# POST /Nodes/{nodeName}/$/Restart
# operationId: RestartNode
export def "nodes-restart RestartNode" [
  nodeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Nodes/($nodeName)/$/Restart" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about a Service Fabric partition.
#
# GET /Partitions/{partitionId}
# operationId: GetPartitionInfo
export def "partitions GetPartitionInfo" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<HealthState: string, PartitionInformation: record<Id: string, ServicePartitionKind: string>, PartitionStatus: string, ServiceKind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Triggers backup of the partition's state.
#
# POST /Partitions/{partitionId}/$/Backup
# operationId: BackupPartition
export def "partitions-backup BackupPartition" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --BackupTimeout: int # Specifies the maximum amount of time, in minutes, to wait for the backup operation to complete. Post that, the operation completes with timeout error. However, in certain corner cases it could be that though the operation returns back timeout, the backup actually goes through. In case of timeout error, its recommended to invoke this operation again with a greater timeout value. The default value for the same is 10 minutes. (default: 10)
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "BackupTimeout" $BackupTimeout "scalar") (serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/Backup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disables periodic backup of Service Fabric partition which was previously enabled.
#
# POST /Partitions/{partitionId}/$/DisableBackup
# operationId: DisablePartitionBackup
export def "partitions-disable-backup DisablePartitionBackup" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/DisableBackup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enables periodic backup of the stateful persisted partition.
#
# POST /Partitions/{partitionId}/$/EnableBackup
# operationId: EnablePartitionBackup
export def "partitions-enable-backup EnablePartitionBackup" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/EnableBackup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the partition backup configuration information
#
# GET /Partitions/{partitionId}/$/GetBackupConfigurationInfo
# operationId: GetPartitionBackupConfigurationInfo
export def "partitions-get-backup-configuration-info GetPartitionBackupConfigurationInfo" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<PartitionId: string, ServiceName: string, Kind: string, PolicyInheritedFrom: string, PolicyName: string, SuspensionInfo: record<IsSuspended: bool, SuspensionInheritedFrom: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetBackupConfigurationInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets details for the latest backup triggered for this partition.
#
# GET /Partitions/{partitionId}/$/GetBackupProgress
# operationId: GetPartitionBackupProgress
export def "partitions-get-backup-progress GetPartitionBackupProgress" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<BackupId: string, BackupLocation: string, BackupState: string, EpochOfLastBackupRecord: record<ConfigurationVersion: string, DataLossVersion: string>, FailureError: record<Code: string, Message: string>, LsnOfLastBackupRecord: string, TimeStampUtc: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetBackupProgress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of backups available for the specified partition.
#
# GET /Partitions/{partitionId}/$/GetBackups
# operationId: GetPartitionBackupList
export def "partitions-get-backups GetPartitionBackupList" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --Latest: string@bool-completer # Specifies whether to get only the most recent backup available for a partition for the specified time range. (default: false)
  --StartDateTimeFilter: string # Specify the start date time from which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, all backups from the beginning are enumerated. (format: date-time)
  --EndDateTimeFilter: string # Specify the end date time till which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, enumeration is done till the most recent backup. (format: date-time)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "Latest" $Latest "scalar") (serialize-qp "StartDateTimeFilter" $StartDateTimeFilter "scalar") (serialize-qp "EndDateTimeFilter" $EndDateTimeFilter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetBackups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of the specified Service Fabric partition.
#
# GET /Partitions/{partitionId}/$/GetHealth
# operationId: GetPartitionHealth
export def "partitions-get-health GetPartitionHealth" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ReplicasHealthStateFilter: int # Allows filtering the collection of ReplicaHealthState objects on the partition. The value can be obtained from members or bitwise operations on members of HealthStateFilter. Only replicas that match the filter will be returned. All replicas will be used to evaluate the aggregated health state. If not specified, all entries will be returned.The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) will be returned. The possible values for this parameter include integer value of one of the following health states.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ExcludeHealthStatistics: string@bool-completer # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<PartitionId: string, ReplicaHealthStates: table<PartitionId: string, ServiceKind: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "ReplicasHealthStateFilter" $ReplicasHealthStateFilter "scalar") (serialize-qp "ExcludeHealthStatistics" $ExcludeHealthStatistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of the specified Service Fabric partition, by using the specified health policy.
#
# POST /Partitions/{partitionId}/$/GetHealth
# operationId: GetPartitionHealthUsingPolicy
export def "partitions-get-health GetPartitionHealthUsingPolicy" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ReplicasHealthStateFilter: int # Allows filtering the collection of ReplicaHealthState objects on the partition. The value can be obtained from members or bitwise operations on members of HealthStateFilter. Only replicas that match the filter will be returned. All replicas will be used to evaluate the aggregated health state. If not specified, all entries will be returned.The state values are flag-based enumeration, so the value could be a combination of these values obtained using bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) will be returned. The possible values for this parameter include integer value of one of the following health states.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ExcludeHealthStatistics: string@bool-completer # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<PartitionId: string, ReplicaHealthStates: table<PartitionId: string, ServiceKind: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "ReplicasHealthStateFilter" $ReplicasHealthStateFilter "scalar") (serialize-qp "ExcludeHealthStatistics" $ExcludeHealthStatistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the load information of the specified Service Fabric partition.
#
# GET /Partitions/{partitionId}/$/GetLoadInformation
# operationId: GetPartitionLoadInformation
export def "partitions-get-load-information GetPartitionLoadInformation" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<PartitionId: string, PrimaryLoadMetricReports: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: string>, SecondaryLoadMetricReports: table<CurrentValue: string, LastReportedUtc: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetLoadInformation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about replicas of a Service Fabric service partition.
#
# GET /Partitions/{partitionId}/$/GetReplicas
# operationId: GetReplicaInfoList
export def "partitions-get-replicas GetReplicaInfoList" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<Address: string, HealthState: string, LastInBuildDurationInSeconds: string, NodeName: string, ReplicaStatus: string, ServiceKind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetReplicas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about a replica of a Service Fabric partition.
#
# GET /Partitions/{partitionId}/$/GetReplicas/{replicaId}
# operationId: GetReplicaInfo
export def "partitions-get-replicas GetReplicaInfo" [
  partitionId: string
  replicaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Address: string, HealthState: string, LastInBuildDurationInSeconds: string, NodeName: string, ReplicaStatus: string, ServiceKind: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetReplicas/($replicaId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of a Service Fabric stateful service replica or stateless service instance.
#
# GET /Partitions/{partitionId}/$/GetReplicas/{replicaId}/$/GetHealth
# operationId: GetReplicaHealth
export def "partitions-get-replicas-get-health GetReplicaHealth" [
  partitionId: string
  replicaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<PartitionId: string, ServiceKind: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetReplicas/($replicaId)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of a Service Fabric stateful service replica or stateless service instance using the specified policy.
#
# POST /Partitions/{partitionId}/$/GetReplicas/{replicaId}/$/GetHealth
# operationId: GetReplicaHealthUsingPolicy
export def "partitions-get-replicas-get-health GetReplicaHealthUsingPolicy" [
  partitionId: string
  replicaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<PartitionId: string, ServiceKind: string, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetReplicas/($replicaId)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends a health report on the Service Fabric replica.
#
# POST /Partitions/{partitionId}/$/GetReplicas/{replicaId}/$/ReportHealth
# operationId: ReportReplicaHealth
export def "partitions-get-replicas-report-health ReportReplicaHealth" [
  partitionId: string
  replicaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ServiceKind: string@ServiceKind-completer # The kind of service replica (Stateless or Stateful) for which the health is being reported. Following are the possible values. (default: Stateful)
  --Immediate: string@bool-completer # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ServiceKind" $ServiceKind "scalar") (serialize-qp "Immediate" $Immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetReplicas/($replicaId)/$/ReportHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets details for the latest restore operation triggered for this partition.
#
# GET /Partitions/{partitionId}/$/GetRestoreProgress
# operationId: GetPartitionRestoreProgress
export def "partitions-get-restore-progress GetPartitionRestoreProgress" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<FailureError: record<Code: string, Message: string>, RestoreState: string, RestoredEpoch: record<ConfigurationVersion: string, DataLossVersion: string>, RestoredLsn: string, TimeStampUtc: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetRestoreProgress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the name of the Service Fabric service for a partition.
#
# GET /Partitions/{partitionId}/$/GetServiceName
# operationId: GetServiceNameInfo
export def "partitions-get-service-name GetServiceNameInfo" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Id: string, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/GetServiceName" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Moves the primary replica of a partition of a stateful service.
#
# POST /Partitions/{partitionId}/$/MovePrimaryReplica
# operationId: MovePrimaryReplica
export def "partitions-move-primary-replica MovePrimaryReplica" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-7 # The version of the API. This parameter is required and its value must be '6.5'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.5)
  --NodeName: string # The name of the node.
  --IgnoreConstraints: string@bool-completer # Ignore constraints when moving a replica. If this parameter is not specified, all constraints are honored. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "NodeName" $NodeName "scalar") (serialize-qp "IgnoreConstraints" $IgnoreConstraints "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/MovePrimaryReplica" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Moves the secondary replica of a partition of a stateful service.
#
# POST /Partitions/{partitionId}/$/MoveSecondaryReplica
# operationId: MoveSecondaryReplica
export def "partitions-move-secondary-replica MoveSecondaryReplica" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-7 # The version of the API. This parameter is required and its value must be '6.5'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.5)
  --CurrentNodeName: string # The name of the source node for secondary replica move.
  --NewNodeName: string # The name of the target node for secondary replica move. If not specified, replica is moved to a random node.
  --IgnoreConstraints: string@bool-completer # Ignore constraints when moving a replica. If this parameter is not specified, all constraints are honored. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "CurrentNodeName" $CurrentNodeName "scalar") (serialize-qp "NewNodeName" $NewNodeName "scalar") (serialize-qp "IgnoreConstraints" $IgnoreConstraints "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/MoveSecondaryReplica" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Indicates to the Service Fabric cluster that it should attempt to recover a specific partition that is currently stuck in quorum loss.
#
# POST /Partitions/{partitionId}/$/Recover
# operationId: RecoverPartition
export def "partitions-recover RecoverPartition" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/Recover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends a health report on the Service Fabric partition.
#
# POST /Partitions/{partitionId}/$/ReportHealth
# operationId: ReportPartitionHealth
export def "partitions-report-health ReportPartitionHealth" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --Immediate: string@bool-completer # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $Immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/ReportHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resets the current load of a Service Fabric partition.
#
# POST /Partitions/{partitionId}/$/ResetLoad
# operationId: ResetPartitionLoad
export def "partitions-reset-load ResetPartitionLoad" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/ResetLoad" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Triggers restore of the state of the partition using the specified restore partition description.
#
# POST /Partitions/{partitionId}/$/Restore
# operationId: RestorePartition
export def "partitions-restore RestorePartition" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --RestoreTimeout: int # Specifies the maximum amount of time to wait, in minutes, for the restore operation to complete. Post that, the operation returns back with timeout error. However, in certain corner cases it could be that the restore operation goes through even though it completes with timeout. In case of timeout error, its recommended to invoke this operation again with a greater timeout value. the default value for the same is 10 minutes. (default: 10)
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RestoreTimeout" $RestoreTimeout "scalar") (serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/Restore" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resumes periodic backup of partition which was previously suspended.
#
# POST /Partitions/{partitionId}/$/ResumeBackup
# operationId: ResumePartitionBackup
export def "partitions-resume-backup ResumePartitionBackup" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/ResumeBackup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suspends periodic backup for the specified partition.
#
# POST /Partitions/{partitionId}/$/SuspendBackup
# operationId: SuspendPartitionBackup
export def "partitions-suspend-backup SuspendPartitionBackup" [
  partitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Partitions/($partitionId)/$/SuspendBackup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all the application resources.
#
# GET /Resources/Applications
# operationId: MeshApplication_List
export def "resources-applications List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<identity: record, name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Resources/Applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the Application resource.
#
# DELETE /Resources/Applications/{applicationResourceName}
# operationId: MeshApplication_Delete
export def "resources-applications Delete" [
  applicationResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Applications/($applicationResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the Application resource with the given name.
#
# GET /Resources/Applications/{applicationResourceName}
# operationId: MeshApplication_Get
export def "resources-applications Get" [
  applicationResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<identity: record<principalId: string, tenantId: string, tokenServiceEndpoint: string, type: string, userAssignedIdentities: record>, name: string, properties: record<debugParams: string, description: string, diagnostics: record<defaultSinkRefs: list, enabled: bool, sinks: list>, healthState: string, serviceNames: list<string>, services: list<record>, status: string, statusDetails: string, unhealthyEvaluation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Applications/($applicationResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates or updates a Application resource.
#
# PUT /Resources/Applications/{applicationResourceName}
# operationId: MeshApplication_CreateOrUpdate
export def "resources-applications CreateOrUpdate" [
  applicationResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<identity: record<principalId: string, tenantId: string, tokenServiceEndpoint: string, type: string, userAssignedIdentities: record>, name: string, properties: record<debugParams: string, description: string, diagnostics: record<defaultSinkRefs: list, enabled: bool, sinks: list>, healthState: string, serviceNames: list<string>, services: list<record>, status: string, statusDetails: string, unhealthyEvaluation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Applications/($applicationResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all the service resources.
#
# GET /Resources/Applications/{applicationResourceName}/Services
# operationId: MeshService_List
export def "resources-applications-services List" [
  applicationResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Applications/($applicationResourceName)/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the Service resource with the given name.
#
# GET /Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}
# operationId: MeshService_Get
export def "resources-applications-services Get" [
  applicationResourceName: string
  serviceResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<codePackages: list<record>, diagnostics: record<enabled: bool, sinkRefs: list>, networkRefs: list<record>, osType: string, autoScalingPolicies: list<record>, description: string, healthState: string, identityRefs: list<record>, replicaCount: int, status: string, statusDetails: string, unhealthyEvaluation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Applications/($applicationResourceName)/Services/($serviceResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all the replicas of a service.
#
# GET /Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}/Replicas
# operationId: MeshServiceReplica_List
export def "resources-applications-services-replicas List" [
  applicationResourceName: string
  serviceResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<replicaName: string, codePackages: list, diagnostics: record, networkRefs: list, osType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Applications/($applicationResourceName)/Services/($serviceResourceName)/Replicas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the given replica of the service of an application.
#
# GET /Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}/Replicas/{replicaName}
# operationId: MeshServiceReplica_Get
export def "resources-applications-services-replicas Get" [
  applicationResourceName: string
  serviceResourceName: string
  replicaName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<replicaName: string, codePackages: table<commands: list, diagnostics: record, endpoints: list, entrypoint: string, environmentVariables: list, image: string, imageRegistryCredential: record, instanceView: record, labels: list, name: string, reliableCollectionsRefs: list, resources: record, settings: list, volumeRefs: list, volumes: list>, diagnostics: record<enabled: bool, sinkRefs: list<string>>, networkRefs: table<endpointRefs: list, name: string>, osType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Applications/($applicationResourceName)/Services/($serviceResourceName)/Replicas/($replicaName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the logs from the container.
#
# GET /Resources/Applications/{applicationResourceName}/Services/{serviceResourceName}/Replicas/{replicaName}/CodePackages/{codePackageName}/Logs
# operationId: MeshCodePackage_GetContainerLogs
export def "resources-applications-services-replicas-code-packages-logs GetContainerLogs" [
  applicationResourceName: string
  serviceResourceName: string
  replicaName: string
  codePackageName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
  --Tail: string # Number of lines to show from the end of the logs. Default is 100. 'all' to show the complete logs.
]: nothing -> record<Content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Tail" $Tail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Applications/($applicationResourceName)/Services/($serviceResourceName)/Replicas/($replicaName)/CodePackages/($codePackageName)/Logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all the gateway resources.
#
# GET /Resources/Gateways
# operationId: MeshGateway_List
export def "resources-gateways List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Resources/Gateways" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the Gateway resource.
#
# DELETE /Resources/Gateways/{gatewayResourceName}
# operationId: MeshGateway_Delete
export def "resources-gateways Delete" [
  gatewayResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Gateways/($gatewayResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the Gateway resource with the given name.
#
# GET /Resources/Gateways/{gatewayResourceName}
# operationId: MeshGateway_Get
export def "resources-gateways Get" [
  gatewayResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<description: string, destinationNetwork: record<endpointRefs: list, name: string>, http: list<record>, ipAddress: string, sourceNetwork: record<endpointRefs: list, name: string>, status: string, statusDetails: string, tcp: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Gateways/($gatewayResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates or updates a Gateway resource.
#
# PUT /Resources/Gateways/{gatewayResourceName}
# operationId: MeshGateway_CreateOrUpdate
export def "resources-gateways CreateOrUpdate" [
  gatewayResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<description: string, destinationNetwork: record<endpointRefs: list, name: string>, http: list<record>, ipAddress: string, sourceNetwork: record<endpointRefs: list, name: string>, status: string, statusDetails: string, tcp: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Gateways/($gatewayResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all the network resources.
#
# GET /Resources/Networks
# operationId: MeshNetwork_List
export def "resources-networks List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Resources/Networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the Network resource.
#
# DELETE /Resources/Networks/{networkResourceName}
# operationId: MeshNetwork_Delete
export def "resources-networks Delete" [
  networkResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Networks/($networkResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the Network resource with the given name.
#
# GET /Resources/Networks/{networkResourceName}
# operationId: MeshNetwork_Get
export def "resources-networks Get" [
  networkResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<description: string, status: string, statusDetails: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Networks/($networkResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates or updates a Network resource.
#
# PUT /Resources/Networks/{networkResourceName}
# operationId: MeshNetwork_CreateOrUpdate
export def "resources-networks CreateOrUpdate" [
  networkResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<description: string, status: string, statusDetails: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Networks/($networkResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all the secret resources.
#
# GET /Resources/Secrets
# operationId: MeshSecret_List
export def "resources-secrets List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Resources/Secrets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the Secret resource.
#
# DELETE /Resources/Secrets/{secretResourceName}
# operationId: MeshSecret_Delete
export def "resources-secrets Delete" [
  secretResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Secrets/($secretResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the Secret resource with the given name.
#
# GET /Resources/Secrets/{secretResourceName}
# operationId: MeshSecret_Get
export def "resources-secrets Get" [
  secretResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<contentType: string, description: string, status: string, statusDetails: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Secrets/($secretResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates or updates a Secret resource.
#
# PUT /Resources/Secrets/{secretResourceName}
# operationId: MeshSecret_CreateOrUpdate
export def "resources-secrets CreateOrUpdate" [
  secretResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<contentType: string, description: string, status: string, statusDetails: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Secrets/($secretResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List names of all values of the specified secret resource.
#
# GET /Resources/Secrets/{secretResourceName}/values
# operationId: MeshSecretValue_List
export def "resources-secrets-values List" [
  secretResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Secrets/($secretResourceName)/values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the specified  value of the named secret resource.
#
# DELETE /Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}
# operationId: MeshSecretValue_Delete
export def "resources-secrets-values Delete" [
  secretResourceName: string
  secretValueResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Secrets/($secretResourceName)/values/($secretValueResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the specified secret value resource.
#
# GET /Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}
# operationId: MeshSecretValue_Get
export def "resources-secrets-values Get" [
  secretResourceName: string
  secretValueResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Secrets/($secretResourceName)/values/($secretValueResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds the specified value as a new version of the specified secret resource.
#
# PUT /Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}
# operationId: MeshSecretValue_AddValue
export def "resources-secrets-values AddValue" [
  secretResourceName: string
  secretValueResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Secrets/($secretResourceName)/values/($secretValueResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the specified value of the secret resource.
#
# POST /Resources/Secrets/{secretResourceName}/values/{secretValueResourceName}/list_value
# operationId: MeshSecretValue_Show
export def "resources-secrets-values-list-value Show" [
  secretResourceName: string
  secretValueResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Secrets/($secretResourceName)/values/($secretValueResourceName)/list_value" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all the volume resources.
#
# GET /Resources/Volumes
# operationId: MeshVolume_List
export def "resources-volumes List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<ContinuationToken: string, Items: table<name: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Resources/Volumes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the Volume resource.
#
# DELETE /Resources/Volumes/{volumeResourceName}
# operationId: MeshVolume_Delete
export def "resources-volumes Delete" [
  volumeResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Volumes/($volumeResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the Volume resource with the given name.
#
# GET /Resources/Volumes/{volumeResourceName}
# operationId: MeshVolume_Get
export def "resources-volumes Get" [
  volumeResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<azureFileParameters: record<accountKey: string, accountName: string, shareName: string>, description: string, provider: string, status: string, statusDetails: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Volumes/($volumeResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates or updates a Volume resource.
#
# PUT /Resources/Volumes/{volumeResourceName}
# operationId: MeshVolume_CreateOrUpdate
export def "resources-volumes CreateOrUpdate" [
  volumeResourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-5 # The version of the API. This parameter is required and its value must be '6.4-preview'. (default: 6.4-preview)
]: nothing -> record<name: string, properties: record<azureFileParameters: record<accountKey: string, accountName: string, shareName: string>, description: string, provider: string, status: string, statusDetails: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Resources/Volumes/($volumeResourceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Indicates to the Service Fabric cluster that it should attempt to recover the specified service that is currently stuck in quorum loss.
#
# POST /Services/$/{serviceId}/$/GetPartitions/$/Recover
# operationId: RecoverServicePartitions
export def "services-get-partitions-recover RecoverServicePartitions" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/$/($serviceId)/$/GetPartitions/$/Recover" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes an existing Service Fabric service.
#
# POST /Services/{serviceId}/$/Delete
# operationId: DeleteService
export def "services-delete DeleteService" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --ForceRemove: string@bool-completer # Remove a Service Fabric application or service forcefully without going through the graceful shutdown sequence. This parameter can be used to forcefully delete an application or service for which delete is timing out due to issues in the service code that prevents graceful close of replicas.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ForceRemove" $ForceRemove "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/Delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disables periodic backup of Service Fabric service which was previously enabled.
#
# POST /Services/{serviceId}/$/DisableBackup
# operationId: DisableServiceBackup
export def "services-disable-backup DisableServiceBackup" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/DisableBackup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enables periodic backup of stateful partitions under this Service Fabric service.
#
# POST /Services/{serviceId}/$/EnableBackup
# operationId: EnableServiceBackup
export def "services-enable-backup EnableServiceBackup" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/EnableBackup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the name of the Service Fabric application for a service.
#
# GET /Services/{serviceId}/$/GetApplicationName
# operationId: GetApplicationNameInfo
export def "services-get-application-name GetApplicationNameInfo" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Id: string, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/GetApplicationName" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the Service Fabric service backup configuration information.
#
# GET /Services/{serviceId}/$/GetBackupConfigurationInfo
# operationId: GetServiceBackupConfigurationInfo
export def "services-get-backup-configuration-info GetServiceBackupConfigurationInfo" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<Kind: string, PolicyInheritedFrom: string, PolicyName: string, SuspensionInfo: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/GetBackupConfigurationInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of backups available for every partition in this service.
#
# GET /Services/{serviceId}/$/GetBackups
# operationId: GetServiceBackupList
export def "services-get-backups GetServiceBackupList" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
  --Latest: string@bool-completer # Specifies whether to get only the most recent backup available for a partition for the specified time range. (default: false)
  --StartDateTimeFilter: string # Specify the start date time from which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, all backups from the beginning are enumerated. (format: date-time)
  --EndDateTimeFilter: string # Specify the end date time till which to enumerate backups, in datetime format. The date time must be specified in ISO8601 format. This is an optional parameter. If not specified, enumeration is done till the most recent backup. (format: date-time)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
]: nothing -> record<ContinuationToken: string, Items: table<ApplicationName: string, BackupChainId: string, BackupId: string, BackupLocation: string, BackupType: string, CreationTimeUtc: string, EpochOfLastBackupRecord: record, FailureError: record, LsnOfLastBackupRecord: string, PartitionInformation: record, ServiceManifestVersion: string, ServiceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar") (serialize-qp "Latest" $Latest "scalar") (serialize-qp "StartDateTimeFilter" $StartDateTimeFilter "scalar") (serialize-qp "EndDateTimeFilter" $EndDateTimeFilter "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "MaxResults" $MaxResults "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/GetBackups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the description of an existing Service Fabric service.
#
# GET /Services/{serviceId}/$/GetDescription
# operationId: GetServiceDescription
export def "services-get-description GetServiceDescription" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ApplicationName: string, CorrelationScheme: table<Scheme: string, ServiceName: string>, DefaultMoveCost: string, InitializationData: list<int>, IsDefaultMoveCostSpecified: bool, PartitionDescription: record<PartitionScheme: string>, PlacementConstraints: string, ScalingPolicies: table<ScalingMechanism: record, ScalingTrigger: record>, ServiceDnsName: string, ServiceKind: string, ServiceLoadMetrics: table<DefaultLoad: int, Name: string, PrimaryDefaultLoad: int, SecondaryDefaultLoad: int, Weight: string>, ServiceName: string, ServicePackageActivationMode: string, ServicePlacementPolicies: table<Type: string>, ServiceTypeName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/GetDescription" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of the specified Service Fabric service.
#
# GET /Services/{serviceId}/$/GetHealth
# operationId: GetServiceHealth
export def "services-get-health GetServiceHealth" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --PartitionsHealthStateFilter: int # Allows filtering of the partitions health state objects returned in the result of service health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only partitions that match the filter are returned. All partitions are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these value obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of partitions with HealthState value of OK (2) and Warning (4) will be returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ExcludeHealthStatistics: string@bool-completer # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Name: string, PartitionHealthStates: table<PartitionId: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "PartitionsHealthStateFilter" $PartitionsHealthStateFilter "scalar") (serialize-qp "ExcludeHealthStatistics" $ExcludeHealthStatistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the health of the specified Service Fabric service, by using the specified health policy.
#
# POST /Services/{serviceId}/$/GetHealth
# operationId: GetServiceHealthUsingPolicy
export def "services-get-health GetServiceHealthUsingPolicy" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --EventsHealthStateFilter: int # Allows filtering the collection of HealthEvent objects returned based on health state. The possible values for this parameter include integer value of one of the following health states. Only events that match the filter are returned. All events are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these values, obtained using the bitwise 'OR' operator. For example, If the provided value is 6 then all of the events with HealthState value of OK (2) and Warning (4) are returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --PartitionsHealthStateFilter: int # Allows filtering of the partitions health state objects returned in the result of service health query based on their health state. The possible values for this parameter include integer value of one of the following health states. Only partitions that match the filter are returned. All partitions are used to evaluate the aggregated health state. If not specified, all entries are returned. The state values are flag-based enumeration, so the value could be a combination of these value obtained using bitwise 'OR' operator. For example, if the provided value is 6 then health state of partitions with HealthState value of OK (2) and Warning (4) will be returned.  - Default - Default value. Matches any HealthState. The value is zero. - None - Filter that doesn't match any HealthState value. Used in order to return no results on a given collection of states. The value is 1. - Ok - Filter that matches input with HealthState value Ok. The value is 2. - Warning - Filter that matches input with HealthState value Warning. The value is 4. - Error - Filter that matches input with HealthState value Error. The value is 8. - All - Filter that matches input with any HealthState value. The value is 65535. (default: 0)
  --ExcludeHealthStatistics: string@bool-completer # Indicates whether the health statistics should be returned as part of the query result. False by default. The statistics show the number of children entities in health state Ok, Warning, and Error. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Name: string, PartitionHealthStates: table<PartitionId: string, AggregatedHealthState: string>, AggregatedHealthState: string, HealthEvents: table<IsExpired: bool, LastErrorTransitionAt: string, LastModifiedUtcTimestamp: string, LastOkTransitionAt: string, LastWarningTransitionAt: string, SourceUtcTimestamp: string, Description: string, HealthState: string, Property: string, RemoveWhenExpired: bool, SequenceNumber: string, SourceId: string, TimeToLiveInMilliSeconds: string>, HealthStatistics: record<HealthStateCountList: list<record>>, UnhealthyEvaluations: table<HealthEvaluation: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "EventsHealthStateFilter" $EventsHealthStateFilter "scalar") (serialize-qp "PartitionsHealthStateFilter" $PartitionsHealthStateFilter "scalar") (serialize-qp "ExcludeHealthStatistics" $ExcludeHealthStatistics "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/GetHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the list of partitions of a Service Fabric service.
#
# GET /Services/{serviceId}/$/GetPartitions
# operationId: GetPartitionInfoList
export def "services-get-partitions GetPartitionInfoList" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, Items: table<HealthState: string, PartitionInformation: record, PartitionStatus: string, ServiceKind: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/GetPartitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the information about unplaced replica of the service.
#
# GET /Services/{serviceId}/$/GetUnplacedReplicaInformation
# operationId: GetUnplacedReplicaInformation
export def "services-get-unplaced-replica-information GetUnplacedReplicaInformation" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --PartitionId: string # The identity of the partition. (format: uuid)
  --OnlyQueryPrimaries: string@bool-completer # Indicates that unplaced replica information will be queries only for primary replicas. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<PartitionId: string, ServiceName: string, UnplacedReplicaDetails: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "PartitionId" $PartitionId "scalar") (serialize-qp "OnlyQueryPrimaries" $OnlyQueryPrimaries "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/GetUnplacedReplicaInformation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends a health report on the Service Fabric service.
#
# POST /Services/{serviceId}/$/ReportHealth
# operationId: ReportServiceHealth
export def "services-report-health ReportServiceHealth" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --Immediate: string@bool-completer # A flag that indicates whether the report should be sent immediately. A health report is sent to a Service Fabric gateway Application, which forwards to the health store. If Immediate is set to true, the report is sent immediately from HTTP Gateway to the health store, regardless of the fabric client settings that the HTTP Gateway Application is using. This is useful for critical reports that should be sent as soon as possible. Depending on timing and other conditions, sending the report may still fail, for example if the HTTP Gateway is closed or the message doesn't reach the Gateway. If Immediate is set to false, the report is sent based on the health client settings from the HTTP Gateway. Therefore, it will be batched according to the HealthReportSendInterval configuration. This is the recommended setting because it allows the health client to optimize health reporting messages to health store as well as health report processing. By default, reports are not sent immediately. (default: false)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Immediate" $Immediate "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/ReportHealth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve a Service Fabric partition.
#
# GET /Services/{serviceId}/$/ResolvePartition
# operationId: ResolveService
export def "services-resolve-partition ResolveService" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --PartitionKeyType: int # Key type for the partition. This parameter is required if the partition scheme for the service is Int64Range or Named. The possible values are following. - None (1) - Indicates that the PartitionKeyValue parameter is not specified. This is valid for the partitions with partitioning scheme as Singleton. This is the default value. The value is 1. - Int64Range (2) - Indicates that the PartitionKeyValue parameter is an int64 partition key. This is valid for the partitions with partitioning scheme as Int64Range. The value is 2. - Named (3) - Indicates that the PartitionKeyValue parameter is a name of the partition. This is valid for the partitions with partitioning scheme as Named. The value is 3.
  --PartitionKeyValue: string # Partition key. This is required if the partition scheme for the service is Int64Range or Named.  This is not the partition ID, but rather, either the integer key value, or the name of the partition ID. For example, if your service is using ranged partitions from 0 to 10, then they PartitionKeyValue would be an integer in that range. Query service description to see the range or name.
  --PreviousRspVersion: string # The value in the Version field of the response that was received previously. This is required if the user knows that the result that was gotten previously is stale.
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Endpoints: table<Address: string, Kind: string>, Name: string, PartitionInformation: record<Id: string, ServicePartitionKind: string>, Version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "PartitionKeyType" $PartitionKeyType "scalar") (serialize-qp "PartitionKeyValue" $PartitionKeyValue "scalar") (serialize-qp "PreviousRspVersion" $PreviousRspVersion "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/ResolvePartition" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resumes periodic backup of a Service Fabric service which was previously suspended.
#
# POST /Services/{serviceId}/$/ResumeBackup
# operationId: ResumeServiceBackup
export def "services-resume-backup ResumeServiceBackup" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/ResumeBackup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suspends periodic backup for the specified Service Fabric service.
#
# POST /Services/{serviceId}/$/SuspendBackup
# operationId: SuspendServiceBackup
export def "services-suspend-backup SuspendServiceBackup" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-1 # The version of the API. This parameter is required and its value must be '6.4'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.4)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/SuspendBackup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a Service Fabric service using the specified update description.
#
# POST /Services/{serviceId}/$/Update
# operationId: UpdateService
export def "services-update UpdateService" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/Services/($serviceId)/$/Update" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the status of Chaos.
#
# GET /Tools/Chaos
# operationId: GetChaos
export def "tools-chaos GetChaos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ChaosParameters: record<ChaosTargetFilter: record<ApplicationInclusionList: list, NodeTypeInclusionList: list>, ClusterHealthPolicy: record<ApplicationTypeHealthPolicyMap: list, ConsiderWarningAsError: bool, MaxPercentUnhealthyApplications: int, MaxPercentUnhealthyNodes: int>, Context: record<Map: any>, EnableMoveReplicaFaults: bool, MaxClusterStabilizationTimeoutInSeconds: int, MaxConcurrentFaults: int, TimeToRunInSeconds: string, WaitTimeBetweenFaultsInSeconds: int, WaitTimeBetweenIterationsInSeconds: int>, ScheduleStatus: string, Status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Tools/Chaos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Starts Chaos in the cluster.
#
# POST /Tools/Chaos/$/Start
# operationId: StartChaos
export def "tools-chaos-start StartChaos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Tools/Chaos/$/Start" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Stops Chaos if it is running in the cluster and put the Chaos Schedule in a stopped state.
#
# POST /Tools/Chaos/$/Stop
# operationId: StopChaos
export def "tools-chaos-stop StopChaos" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer # The version of the API. This parameter is required and its value must be '6.0'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accept any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0, but if the runtime is 6.1, in order to make it easier to write the clients, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Tools/Chaos/$/Stop" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the next segment of the Chaos events based on the continuation token or the time range.
#
# GET /Tools/Chaos/Events
# operationId: GetChaosEvents
export def "tools-chaos-events GetChaosEvents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --ContinuationToken: string # The continuation token parameter is used to obtain next set of results. A continuation token with a non-empty value is included in the response of the API when the results from the system do not fit in a single response. When this value is passed to the next API call, the API returns next set of results. If there are no further results, then the continuation token does not contain a value. The value of this parameter should not be URL encoded.
  --StartTimeUtc: string # The Windows file time representing the start time of the time range for which a Chaos report is to be generated. Consult [DateTime.ToFileTimeUtc Method](https://msdn.microsoft.com/library/system.datetime.tofiletimeutc(v=vs.110).aspx) for details.
  --EndTimeUtc: string # The Windows file time representing the end time of the time range for which a Chaos report is to be generated. Consult [DateTime.ToFileTimeUtc Method](https://msdn.microsoft.com/library/system.datetime.tofiletimeutc(v=vs.110).aspx) for details.
  --MaxResults: int # The maximum number of results to be returned as part of the paged queries. This parameter defines the upper bound on the number of results returned. The results returned can be less than the specified maximum results if they do not fit in the message as per the max message size restrictions defined in the configuration. If this parameter is zero or not specified, the paged query includes as many results as possible that fit in the return message. (format: int64, default: 0)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<ContinuationToken: string, History: table<ChaosEvent: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "ContinuationToken" $ContinuationToken "scalar") (serialize-qp "StartTimeUtc" $StartTimeUtc "scalar") (serialize-qp "EndTimeUtc" $EndTimeUtc "scalar") (serialize-qp "MaxResults" $MaxResults "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Tools/Chaos/Events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the Chaos Schedule defining when and how to run Chaos.
#
# GET /Tools/Chaos/Schedule
# operationId: GetChaosSchedule
export def "tools-chaos-schedule GetChaosSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Schedule: record<ChaosParametersDictionary: list<record>, ExpiryDate: string, Jobs: list<record>, StartDate: string>, Version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Tools/Chaos/Schedule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the schedule used by Chaos.
#
# POST /Tools/Chaos/Schedule
# operationId: PostChaosSchedule
export def "tools-chaos-schedule PostChaosSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string@api-version-completer-2 # The version of the API. This parameter is required and its value must be '6.2'.  Service Fabric REST API version is based on the runtime version in which the API was introduced or was changed. Service Fabric runtime supports more than one version of the API. This version is the latest supported version of the API. If a lower API version is passed, the returned response may be different from the one documented in this specification.  Additionally the runtime accepts any version that is higher than the latest supported version up to the current version of the runtime. So if the latest API version is 6.0 and the runtime is 6.1, the runtime will accept version 6.1 for that API. However the behavior of the API will be as per the documented 6.0 version. (default: 6.2)
  --timeout: int # The server timeout for performing the operation in seconds. This timeout specifies the time duration that the client is willing to wait for the requested operation to complete. The default value for this parameter is 60 seconds. (format: int64, default: 60)
]: nothing -> record<Error: record<Code: string, Message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "timeout" $timeout "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Tools/Chaos/Schedule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
