# Auto-generated client for VSOnline vv1
# Source: https://api.apis.guru/v2/specs/visualstudio.com/v1/openapi.json
# Auth: --token flag or $env.VSONLINE_TOKEN

const BASE_URL = "https://online.visualstudio.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VSONLINE_TOKEN | default "" }
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

def base-url-completer [] { ["https://online.visualstudio.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def privacy-completer [] { ["0 (Private)" "1 (Public)" "2 (Org)"] }
def tunnel-type-completer [] { ["0 (Basis)" "1 (Liveshare)"] }
def new-value-completer [] { ["0 (None)" "1 (Created)" "10 (Archived)" "11 (Starting)" "12 (ShuttingDown)" "13 (Failed)" "14 (Exporting)" "15 (Updating)" "16 (Rebuilding)" "2 (Queued)" "3 (Provisioning)" "4 (Available)" "5 (Awaiting)" "6 (Unavailable)" "7 (Deleted)" "8 (Moved)" "9 (Shutdown)"] }
def old-value-completer [] { ["0 (None)" "1 (Created)" "10 (Archived)" "11 (Starting)" "12 (ShuttingDown)" "13 (Failed)" "14 (Exporting)" "15 (Updating)" "16 (Rebuilding)" "2 (Queued)" "3 (Provisioning)" "4 (Available)" "5 (Awaiting)" "6 (Unavailable)" "7 (Deleted)" "8 (Moved)" "9 (Shutdown)"] }
def storage-type-completer [] { ["0 (V1)" "1 (V2)"] }
def location-completer [] { ["1001 (SouthAfricaNorth)" "1002 (SouthAfricaWest)" "101 (EastAsia)" "102 (SouthEastAsia)" "1201 (UaeCentral)" "1202 (UaeNorth)" "1401 (UkSouth)" "1402 (UkWest)" "1501 (CentralUs)" "1502 (EastUs)" "1503 (EastUs2)" "1504 (NorthCentralUs)" "1505 (SouthCentralUs)" "1506 (WestCentralUs)" "1507 (WestUs)" "1508 (WestUs2)" "1509 (WestUs3)" "1601 (CentralUsEuap)" "1602 (EastUs2Euap)" "1701 (SwitzerlandNorth)" "1702 (SwitzerlandWest)" "1801 (GermanyNorth)" "1802 (GermanyWestCentral)" "1901 (NorwayWest)" "1902 (NorwayEast)" "201 (AustraliaCentral)" "202 (AustraliaCentral2)" "203 (AustraliaEast)" "205 (AustraliaSouthEast)" "301 (BrazilSouth)" "401 (CanadaCentral)" "402 (CanadaEast)" "501 (NorthEurope)" "502 (WestEurope)" "601 (FranceCentral)" "602 (FranceSouth)" "701 (CentralIndia)" "702 (SouthIndia)" "703 (WestIndia)" "801 (JapanEast)" "802 (JapanWest)" "901 (KoreaCentral)" "902 (KoreaSouth)"] }
def subtype-completer [] { ["0 (Default)" "2 (ShrunkBlob)" "3 (FullBlob)" "4 (UserParametersBlob)" "5 (PrebuildHash)" "6 (VnetInjected)"] }
def type-completer [] { ["1 (ComputeVM)" "10 (VirtualNetwork)" "11 (NetworkSecurityGroup)" "12 (LiveShareWorkspace)" "13 (BasisTunnel)" "14 (StorageBlockBlob)" "15 (DataDisk)" "16 (PortForwardingWorkspace)" "2 (StorageFileShare)" "3 (StorageArchive)" "4 (KeyVault)" "5 (OSDisk)" "6 (NetworkInterface)" "7 (InputQueue)" "8 (Snapshot)" "9 (PoolQueue)"] }
def scope-completer [] { ["1 (Plan)" "2 (User)"] }
def type-completer-1 [] { ["1 (EnvironmentVariable)" "2 (ContainerRegistry)"] }
def region-completer [] { ["1001 (SouthAfricaNorth)" "1002 (SouthAfricaWest)" "101 (EastAsia)" "102 (SouthEastAsia)" "1201 (UaeCentral)" "1202 (UaeNorth)" "1401 (UkSouth)" "1402 (UkWest)" "1501 (CentralUs)" "1502 (EastUs)" "1503 (EastUs2)" "1504 (NorthCentralUs)" "1505 (SouthCentralUs)" "1506 (WestCentralUs)" "1507 (WestUs)" "1508 (WestUs2)" "1509 (WestUs3)" "1601 (CentralUsEuap)" "1602 (EastUs2Euap)" "1701 (SwitzerlandNorth)" "1702 (SwitzerlandWest)" "1801 (GermanyNorth)" "1802 (GermanyWestCentral)" "1901 (NorwayWest)" "1902 (NorwayEast)" "201 (AustraliaCentral)" "202 (AustraliaCentral2)" "203 (AustraliaEast)" "205 (AustraliaSouthEast)" "301 (BrazilSouth)" "401 (CanadaCentral)" "402 (CanadaEast)" "501 (NorthEurope)" "502 (WestEurope)" "601 (FranceCentral)" "602 (FranceSouth)" "701 (CentralIndia)" "702 (SouthIndia)" "703 (WestIndia)" "801 (JapanEast)" "802 (JapanWest)" "901 (KoreaCentral)" "902 (KoreaSouth)"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "agent-telemetry create" } } | get name | first)
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

# POST /api/v1/AgentTelemetry
export def "agent-telemetry create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/AgentTelemetry")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/AgentTelemetry/standalone
export def "agent-telemetry-standalone create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/AgentTelemetry/standalone")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /api/v1/Agents/{family}
export def "agents get" [
  family: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<assetUri: string, family: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({family: (encode-path-segment $family)} | format pattern "/api/v1/Agents/{family}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Environments
export def "environments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string
  --plan-id: string
  --deleted: oneof<nothing, bool> # default: false
]: nothing -> table<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list, imageAllowList: list>, seed: record<cloneUrl: string, gitConfig: record, recurseClone: bool, repository: record, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "planId" $plan_id "scalar") (serialize-qp "deleted" $deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Environments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Environments
#
# --billableOwner shape: {id?: string, login?: string, type?: "0 (User)"|"1 (Organization)"}
# --connection shape: {connectionServiceUri?: string, connectionSessionId?: string, connectionSessionPath?: string, hostPublicKeys?: list<string>, relayEndpoint?: string, relaySasToken?: string, sessionToken?: string, tunnelProperties?: record}
# --experimentalFeatures shape: {enableDynamicHttpsDetection?: bool, queueResourceAllocation?: bool, usePrebuildFastPathIfAvailable?: bool, usePrebuiltImages?: bool, useStorageV2?: bool}
# --identity shape: {displayName?: string, id?: string, userName?: string}
# --netmonCorrelationData shape: {billableOwnerCreatedAt?: string, billableOwnerDatabaseId?: string, billableOwnerGlobalRelayId?: string, billableOwnerPlan?: string, ownerCreatedAt?: string, ownerDatabaseId?: string, ownerGlobalRelayId?: string, ownerPlan?: string, repositoryCreatedAt?: string, repositoryDatabaseId?: string, repositoryGlobalRelayId?: string, repositoryPrivate?: bool}
# --personalization shape: {dotfilesInstallCommand?: string, dotfilesRepository?: string, dotfilesTargetPath?: string}
# --runtimeConstraints shape: {allowedPortPrivacySettings?: list<int>, imageAllowList?: list<string>}
# --secrets item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
# --seed shape: {cloneUrl?: string, gitConfig?: record, recurseClone?: bool, repository?: record, seedMoniker?: string, seedType?: string}
@deprecated --flag location
@deprecated --flag platform
export def "environments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --access: oneof<nothing, bool>
  --analytics-tracking-id: string # nullable
  --auto-shutdown-delay-minutes: int # format: int32
  --billable-owner: record # shape: {id?: string, login?: string, type?: "0 (User)"|"1 (Organization)"}
  --connection: record # shape: {connectionServiceUri?: string, connectionSessionId?: string, connectionSessionPath?: string, hostPublicKeys?: list<string>, relayEndpoint?: string, relaySasToken?: string, sessionToken?: string, tunnelProperties?: record}
  --container-image: string # nullable
  --create-as-prebuild: oneof<nothing, bool>
  --dev-container-json: string # nullable
  --dev-container-path: string # nullable
  --experimental-features: record # shape: {enableDynamicHttpsDetection?: bool, queueResourceAllocation?: bool, usePrebuildFastPathIfAvailable?: bool, usePrebuiltImages?: bool, useStorageV2?: bool}
  --features: record # nullable
  friendly_name: string
  --git-hub-api-url: string # nullable
  --git-hub-app-url: string # nullable
  --git-hub-pfs-auth-endpoint: string # nullable
  --github-environment-endpoint: string # nullable
  --has-devcontainer-json: oneof<nothing, bool>
  --identity: record # shape: {displayName?: string, id?: string, userName?: string}
  --label: string # nullable
  --location: string # DEPRECATED, nullable
  --netmon-correlation-data: record # shape: {billableOwnerCreatedAt?: string, billableOwnerDatabaseId?: string, billableOwnerGlobalRelayId?: string, billableOwnerPlan?: string, ownerCreatedAt?: string, ownerDatabaseId?: string, ownerGlobalRelayId?: string, ownerPlan?: string, repositoryCreatedAt?: string, repositoryDatabaseId?: string, repositoryGlobalRelayId?: string, repositoryPrivate?: bool}
  --personalization: record # shape: {dotfilesInstallCommand?: string, dotfilesRepository?: string, dotfilesTargetPath?: string}
  --plan-id: string # nullable
  --platform: string # DEPRECATED, nullable
  --runtime-constraints: record # shape: {allowedPortPrivacySettings?: list<int>, imageAllowList?: list<string>}
  --secrets: list # nullable — item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
  --seed: record # shape: {cloneUrl?: string, gitConfig?: record, recurseClone?: bool, repository?: record, seedMoniker?: string, seedType?: string}
  --sku-name: string # nullable
  --test-account: oneof<nothing, bool>
  type: string
  --user-tier: string # nullable
  --working-directory: string # nullable
]: any -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access" $access "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Environments" $qp)
  let req_body = {"analyticsTrackingId": $analytics_tracking_id, "autoShutdownDelayMinutes": $auto_shutdown_delay_minutes, "billableOwner": $billable_owner, "connection": $connection, "containerImage": $container_image, "createAsPrebuild": $create_as_prebuild, "devContainerJson": $dev_container_json, "devContainerPath": $dev_container_path, "experimentalFeatures": $experimental_features, "features": $features, "friendlyName": $friendly_name, "gitHubApiUrl": $git_hub_api_url, "gitHubAppUrl": $git_hub_app_url, "gitHubPfsAuthEndpoint": $git_hub_pfs_auth_endpoint, "githubEnvironmentEndpoint": $github_environment_endpoint, "hasDevcontainerJson": $has_devcontainer_json, "identity": $identity, "label": $label, "location": $location, "netmonCorrelationData": $netmon_correlation_data, "personalization": $personalization, "planId": $plan_id, "platform": $platform, "runtimeConstraints": $runtime_constraints, "secrets": $secrets, "seed": $seed, "skuName": $sku_name, "testAccount": $test_account, "type": $type, "userTier": $user_tier, "workingDirectory": $working_directory} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /api/v1/Environments/{environmentId}
export def "environments delete" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Environments/{environmentId}
#
# operationId: GetEnvironmentRoute
export def "environments get-route" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --connect: oneof<nothing, bool>
  --pf-connect: oneof<nothing, bool>
  --deleted: oneof<nothing, bool> # default: false
]: nothing -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connect" $connect "scalar") (serialize-qp "pfConnect" $pf_connect "scalar") (serialize-qp "deleted" $deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/v1/Environments/{environmentId}
#
# --failoverDetails shape: {failoverEnabled?: bool, ... (1 more fields)}
export def "environments update" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --auto-shutdown-delay-minutes: int # nullable, format: int32
  --failover-details: record # shape: {failoverEnabled?: bool, ... (1 more fields)}
  --friendly-name: string # nullable
  --plan-access-token: string # nullable
  --plan-id: string # nullable
  --sku-name: string # nullable
]: any -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}"))
  let req_body = {"autoShutdownDelayMinutes": $auto_shutdown_delay_minutes, "failoverDetails": $failover_details, "friendlyName": $friendly_name, "planAccessToken": $plan_access_token, "planId": $plan_id, "skuName": $sku_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/Environments/{environmentId}/_callback
#
# operationId: UpdateEnvironmentRoute
# --payload shape: {sessionId?: string, sessionPath?: string}
export def "environments-callback update-route" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --payload: record # shape: {sessionId?: string, sessionPath?: string}
  type: string
]: any -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/_callback"))
  let req_body = {"payload": $payload, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /api/v1/Environments/{environmentId}/archive
export def "environments-archive get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/archive"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Environments/{environmentId}/archive
export def "environments-archive create" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/archive"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Environments/{environmentId}/export
export def "environments-export create" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/export"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/v1/Environments/{environmentId}/folder
export def "environments-folder update" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --recent-folder-paths: list<string> # nullable
]: any -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/folder"))
  let req_body = {"recentFolderPaths": $recent_folder_paths} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /api/v1/Environments/{environmentId}/heartbeattoken
export def "environments-heartbeattoken get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/heartbeattoken"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Environments/{environmentId}/notify
export def "environments-notify create" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --details: string # nullable
  --display-mode: string # nullable
  --message: string # nullable
  --modal: oneof<nothing, bool>
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/notify"))
  let req_body = {"details": $details, "displayMode": $display_mode, "message": $message, "modal": $modal} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /api/v1/Environments/{environmentId}/ports/{port}
export def "environments-ports delete" [
  environment_id: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id), port: (encode-path-segment $port)} | format pattern "/api/v1/Environments/{environment_id}/ports/{port}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/Environments/{environmentId}/ports/{port}
export def "environments-ports update" [
  environment_id: string
  port: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --privacy: int@privacy-completer # format: int32
  --tunnel-type: int@tunnel-type-completer # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id), port: (encode-path-segment $port)} | format pattern "/api/v1/Environments/{environment_id}/ports/{port}"))
  let req_body = {"privacy": $privacy, "tunnelType": $tunnel_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PATCH /api/v1/Environments/{environmentId}/restore
export def "environments-restore update" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/restore"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/Environments/{environmentId}/secrets
#
# --secrets item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
export def "environments-secrets update" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --secrets: list # nullable — item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/secrets"))
  let req_body = {"secrets": $secrets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/Environments/{environmentId}/shutdown
export def "environments-shutdown create" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/shutdown"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Environments/{environmentId}/start
export def "environments-start create" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --access: oneof<nothing, bool>
]: nothing -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access" $access "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/start") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Environments/{environmentId}/state
export def "environments-state get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/state"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Environments/{environmentId}/updates
export def "environments-updates get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Environments/{environment_id}/updates"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/GenevaActions/Billing/resend
export def "geneva-actions-billing-resend create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --end-time: string # format: date-time
  --start-time: string # format: date-time
]: any -> record<billGenerationTime: string, environmentId: string, id: string, location: int, partitionKey: string, periodEnd: string, periodStart: string, plan: record<location: int, name: string, providerNamespace: string, resourceGroup: string, resourceId: string, subscription: string>, usage: record, usageDetail: table<endState: int, id: string, resourceUsage: record, sku: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/Billing/resend")
  let req_body = {"endTime": $end_time, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /api/v1/GenevaActions/Billing/{environmentId}
export def "geneva-actions-billing get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start-time: string
  --end-time: string
]: nothing -> record<billGenerationTime: string, environmentId: string, id: string, location: int, partitionKey: string, periodEnd: string, periodStart: string, plan: record<location: int, name: string, providerNamespace: string, resourceGroup: string, resourceId: string, subscription: string>, usage: record, usageDetail: table<endState: int, id: string, resourceUsage: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $start_time "scalar") (serialize-qp "endTime" $end_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/GenevaActions/Billing/{environment_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/GenevaActions/Billing/{environmentId}/state-changes
export def "geneva-actions-billing-state-changes get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<environment: record<id: string, name: string, sku: record<name: string, tier: string>, userId: string>, id: string, newValue: int, oldValue: int, partitionKey: string, time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/GenevaActions/Billing/{environment_id}/state-changes"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/GenevaActions/Billing/{environmentId}/state-changes
export def "geneva-actions-billing-state-changes create" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --new-value: int@new-value-completer # format: int32
  --old-value: int@old-value-completer # format: int32
  --time: string # nullable, format: date-time
]: any -> record<environment: record<id: string, name: string, sku: record<name: string, tier: string>, userId: string>, id: string, newValue: int, oldValue: int, partitionKey: string, time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/GenevaActions/Billing/{environment_id}/state-changes"))
  let req_body = {"newValue": $new_value, "oldValue": $old_value, "time": $time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/GenevaActions/Configuration/{target}
export def "geneva-actions-configuration create" [
  target: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comment: string # nullable
  --key: string # nullable
  --value: string # nullable
]: any -> record<comment: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({target: (encode-path-segment $target)} | format pattern "/api/v1/GenevaActions/Configuration/{target}"))
  let req_body = {"comment": $comment, "key": $key, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /api/v1/GenevaActions/Configuration/{target}/{key}
export def "geneva-actions-configuration delete" [
  target: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({target: (encode-path-segment $target), key: (encode-path-segment $key)} | format pattern "/api/v1/GenevaActions/Configuration/{target}/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/GenevaActions/Configuration/{target}/{key}
export def "geneva-actions-configuration get" [
  target: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<comment: string, key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({target: (encode-path-segment $target), key: (encode-path-segment $key)} | format pattern "/api/v1/GenevaActions/Configuration/{target}/{key}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/GenevaActions/Environments/{environmentId}
export def "geneva-actions-environments delete" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deletion-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deletionType" $deletion_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/GenevaActions/Environments/{environment_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/GenevaActions/Environments/{environmentId}
export def "geneva-actions-environments get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/GenevaActions/Environments/{environment_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/GenevaActions/Environments/{environmentId}/archive
export def "geneva-actions-environments-archive update" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/GenevaActions/Environments/{environment_id}/archive"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/GenevaActions/Environments/{environmentId}/archived_storage_sas/{targetBlob}
export def "geneva-actions-environments-archived-storage-sas get" [
  environment_id: string
  target_blob: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id), target_blob: (encode-path-segment $target_blob)} | format pattern "/api/v1/GenevaActions/Environments/{environment_id}/archived_storage_sas/{target_blob}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/GenevaActions/Environments/{environmentId}/shutdown
export def "geneva-actions-environments-shutdown update" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/GenevaActions/Environments/{environment_id}/shutdown"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/GenevaActions/Environments/{environmentId}/upload/running/vm/logs
export def "geneva-actions-environments-upload-running-vm-logs create" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<containerName: string, message: string, pathInContainer: string, storageUri: string, vmResourceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/GenevaActions/Environments/{environment_id}/upload/running/vm/logs"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/GenevaActions/Pools/change-resource-deletion-setting
export def "geneva-actions-pools-change-resource-deletion-setting create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comment: string # nullable
  --enabled: oneof<nothing, bool>
  --pool-code: string # nullable
  --pool-type: string # nullable
  --region: string # nullable
]: any -> record<comment: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/Pools/change-resource-deletion-setting")
  let req_body = {"comment": $comment, "enabled": $enabled, "poolCode": $pool_code, "poolType": $pool_type, "region": $region} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/GenevaActions/Pools/{poolCode}/rotate-pool
export def "geneva-actions-pools-rotate-pool create" [
  pool_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pool_code: (encode-path-segment $pool_code)} | format pattern "/api/v1/GenevaActions/Pools/{pool_code}/rotate-pool"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/GenevaActions/Pools/{target}
export def "geneva-actions-pools create" [
  target: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comment: string # nullable
  --max-target-count: string # nullable
  --min-target-count: string # nullable
  --pool-code: string # nullable
  --pool-type: string # nullable
  --region: string # nullable
  --target-count: string # nullable
]: any -> record<comment: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({target: (encode-path-segment $target)} | format pattern "/api/v1/GenevaActions/Pools/{target}"))
  let req_body = {"comment": $comment, "maxTargetCount": $max_target_count, "minTargetCount": $min_target_count, "poolCode": $pool_code, "poolType": $pool_type, "region": $region, "targetCount": $target_count} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/GenevaActions/Prebuilds/pools/createorupdatesettings
#
# --pools item shape: {poolType?: "0 (None)"|"1 (Blob)"|"2 (CodespacePool)"|"3 (StoragePool)"|"4 (CodespaceAndStoragePool)", skuName?: string, targetCount?: int}
export def "geneva-actions-prebuilds-pools-createorupdatesettings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-name: string # nullable
  --dev-container-path: string # nullable
  --pools: list # nullable — item shape: {poolType?: "0 (None)"|"1 (Blob)"|"2 (CodespacePool)"|"3 (StoragePool)"|"4 (CodespaceAndStoragePool)", skuName?: string, targetCount?: int}
  --repo-id: string # nullable
  --storage-type: int@storage-type-completer # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/Prebuilds/pools/createorupdatesettings")
  let req_body = {"branchName": $branch_name, "devContainerPath": $dev_container_path, "pools": $pools, "repoId": $repo_id, "storageType": $storage_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/GenevaActions/Prebuilds/pools/delete
#
# --pools item shape: {poolType?: "0 (None)"|"1 (Blob)"|"2 (CodespacePool)"|"3 (StoragePool)"|"4 (CodespaceAndStoragePool)", skuName?: string, targetCount?: int}
export def "geneva-actions-prebuilds-pools-delete create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branch-name: string # nullable
  --dev-container-path: string # nullable
  --pools: list # nullable — item shape: {poolType?: "0 (None)"|"1 (Blob)"|"2 (CodespacePool)"|"3 (StoragePool)"|"4 (CodespaceAndStoragePool)", skuName?: string, targetCount?: int}
  --repo-id: string # nullable
  --storage-type: int@storage-type-completer # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/Prebuilds/pools/delete")
  let req_body = {"branchName": $branch_name, "devContainerPath": $dev_container_path, "pools": $pools, "repoId": $repo_id, "storageType": $storage_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/GenevaActions/Privacy/refresh-profile-telemetry-properties
export def "geneva-actions-privacy-refresh-profile-telemetry-properties create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --partner: string # nullable
  --tenant-id: string # nullable
  --user-ids: string # nullable
]: any -> record<failed: table<oid: string, provider: string, tid: string>, succeeded: table<oid: string, provider: string, tid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/Privacy/refresh-profile-telemetry-properties")
  let req_body = {"partner": $partner, "tenantId": $tenant_id, "userIds": $user_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/GenevaActions/Resources/{resourceId}/under-investigation
export def "geneva-actions-resources-under-investigation create" [
  resource_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<investigationStarted: string, resourceId: string, underInvestigation: bool, updated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({resource_id: (encode-path-segment $resource_id)} | format pattern "/api/v1/GenevaActions/Resources/{resource_id}/under-investigation"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/GenevaActions/VnetPoolDefinitions
export def "geneva-actions-vnet-pool-definitions delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dimensions: record
  --is-enabled: oneof<nothing, bool>
  location: int@location-completer # format: int32
  --logical-skus: list<string> # nullable
  subtype: int@subtype-completer # format: int32
  target_count: int # format: int32
  type: int@type-completer # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/VnetPoolDefinitions")
  let req_body = {"dimensions": $dimensions, "isEnabled": $is_enabled, "location": $location, "logicalSkus": $logical_skus, "subtype": $subtype, "targetCount": $target_count, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/GenevaActions/VnetPoolDefinitions
export def "geneva-actions-vnet-pool-definitions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dimensions: record
  --is-enabled: oneof<nothing, bool>
  location: int@location-completer # format: int32
  --logical-skus: list<string> # nullable
  subtype: int@subtype-completer # format: int32
  target_count: int # format: int32
  type: int@type-completer # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/VnetPoolDefinitions")
  let req_body = {"dimensions": $dimensions, "isEnabled": $is_enabled, "location": $location, "logicalSkus": $logical_skus, "subtype": $subtype, "targetCount": $target_count, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/HeartBeat
#
# --collectedDataList item shape: {environmentId?: string, name?: string, parentActivityId?: string, timestamp?: string}
export def "heart-beat create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agent-version: string # nullable
  --collected-data-list: list # nullable — item shape: {environmentId?: string, name?: string, parentActivityId?: string, timestamp?: string}
  --environment-id: string # nullable
  --resource-id: string # format: uuid
  --time-stamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/HeartBeat")
  let req_body = {"agentVersion": $agent_version, "collectedDataList": $collected_data_list, "environmentId": $environment_id, "resourceId": $resource_id, "timeStamp": $time_stamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /api/v1/Locations
export def "locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<available: list<int>, current: int, hostnames: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/Locations")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Locations/{location}
export def "locations get" [
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --plan-id: string
]: nothing -> record<skus: table<availableSettings: record, displayName: string, name: string, os: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location: (encode-path-segment $location)} | format pattern "/api/v1/Locations/{location}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Prebuilds/pools/{poolId}/instances
#
# --environmentOptions shape: {correlationId?: string}
# --secrets item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
export def "prebuilds-pools-instances create" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment-options: record # shape: {correlationId?: string}
  --secrets: list # nullable — item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/api/v1/Prebuilds/pools/{pool_id}/instances"))
  let req_body = {"environmentOptions": $environment_options, "secrets": $secrets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /api/v1/Prebuilds/pools/{poolId}/instances
#
# --environmentOptions shape: {correlationId?: string}
# --secrets item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
export def "prebuilds-pools-instances update" [
  pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment-options: record # shape: {correlationId?: string}
  --secrets: list # nullable — item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pool_id: (encode-path-segment $pool_id)} | format pattern "/api/v1/Prebuilds/pools/{pool_id}/instances"))
  let req_body = {"environmentOptions": $environment_options, "secrets": $secrets} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /api/v1/Prebuilds/template/{environmentId}
#
# operationId: GetTemplateInfoRoute
export def "prebuilds-template get-get-route" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<branchName: string, commitId: string, id: string, isPrebuild: bool, lastUsedTime: string, logicalSkus: list<string>, prebuildHash: string, repoId: int, templateStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Prebuilds/template/{environment_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Prebuilds/templates/repo/{repoId}/branch/{branchName}/hash/{prebuildHash}/location/{location}/skus
#
# operationId: GetPrebuildReadinessRoute
export def "prebuilds-templates-repo-branch-hash-location-skus get-readiness-route" [
  repo_id: string
  branch_name: string
  prebuild_hash: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --storage-type: int@storage-type-completer # format: int32
]: nothing -> record<branchName: string, devContainerPath: string, location: int, poolSkus: list<string>, prebuildHash: string, repoId: string, supportedSkus: list<string>, templateSkus: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storageType" $storage_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({repo_id: (encode-path-segment $repo_id), branch_name: (encode-path-segment $branch_name), prebuild_hash: (encode-path-segment $prebuild_hash), location: (encode-path-segment $location)} | format pattern "/api/v1/Prebuilds/templates/repo/{repo_id}/branch/{branch_name}/hash/{prebuild_hash}/location/{location}/skus") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Sas
export def "sas get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<filters: list<record>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/Sas")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Secrets
export def "secrets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --plan-id: string
]: nothing -> table<filters: list<record>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Secrets" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Secrets
#
# --filters item shape: {type?: "1 (GitRepo)"|"2 (CodespaceName)", value?: string}
export def "secrets create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --plan-id: string
  --filters: list # nullable — item shape: {type?: "1 (GitRepo)"|"2 (CodespaceName)", value?: string}
  --notes: string # nullable
  --scope: int@scope-completer # format: int32
  --secret-name: string # nullable
  --type: int@type-completer-1 # format: int32
  --value: string # nullable
]: any -> record<filters: table<type: int, value: string>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Secrets" $qp)
  let req_body = {"filters": $filters, "notes": $notes, "scope": $scope, "secretName": $secret_name, "type": $type, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /api/v1/Secrets/{secretId}
export def "secrets delete" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --plan-id: string
  --scope: int@scope-completer # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_id: (encode-path-segment $secret_id)} | format pattern "/api/v1/Secrets/{secret_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/Secrets/{secretId}
#
# --filters item shape: {type?: "1 (GitRepo)"|"2 (CodespaceName)", value?: string}
export def "secrets update" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --plan-id: string
  --filters: list # nullable — item shape: {type?: "1 (GitRepo)"|"2 (CodespaceName)", value?: string}
  --notes: string # nullable
  --scope: int@scope-completer # format: int32
  --secret-name: string # nullable
  --value: string # nullable
]: any -> record<filters: table<type: int, value: string>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $plan_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({secret_id: (encode-path-segment $secret_id)} | format pattern "/api/v1/Secrets/{secret_id}") $qp)
  let req_body = {"filters": $filters, "notes": $notes, "scope": $scope, "secretName": $secret_name, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /api/v1/Tenant/{tenantId}
export def "tenant delete" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/api/v1/Tenant/{tenant_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Tenant/{tenantId}
export def "tenant get" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/api/v1/Tenant/{tenant_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/Tenant/{tenantId}
export def "tenant update" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/api/v1/Tenant/{tenant_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/plans/{planName}/deleteAllCodespaces
export def "tokens-plans-delete-all-codespaces create" [
  plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
  --x-subscription-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({plan_name: (encode-path-segment $plan_name)} | format pattern "/api/v1/Tokens/plans/{plan_name}/deleteAllCodespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-subscription-id": $x_subscription_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/plans/{planName}/readAllCodespaces
export def "tokens-plans-read-all-codespaces create" [
  plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
  --x-subscription-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({plan_name: (encode-path-segment $plan_name)} | format pattern "/api/v1/Tokens/plans/{plan_name}/readAllCodespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-subscription-id": $x_subscription_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/plans/{planName}/writeCodespaces
export def "tokens-plans-write-codespaces create" [
  plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
  --x-subscription-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({plan_name: (encode-path-segment $plan_name)} | format pattern "/api/v1/Tokens/plans/{plan_name}/writeCodespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-subscription-id": $x_subscription_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/plans/{planName}/writeDelegates
#
# --identity shape: {displayName?: string, id?: string, username?: string}
export def "tokens-plans-write-delegates create" [
  plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-subscription-id: string
  --environment-ids: list<string> # nullable
  --expiration: string # nullable, format: date-time
  --identity: record # shape: {displayName?: string, id?: string, username?: string}
  --port-numbers: list<int> # nullable
  --scope: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({plan_name: (encode-path-segment $plan_name)} | format pattern "/api/v1/Tokens/plans/{plan_name}/writeDelegates"))
  let req_body = {"environmentIds": $environment_ids, "expiration": $expiration, "identity": $identity, "portNumbers": $port_numbers, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-subscription-id": $x_subscription_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "tokens-subscriptions-resource-groups-providers-plans update" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --headers: record
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), provider_namespace: (encode-path-segment $provider_namespace), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/Tokens/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/{provider_namespace}/plans/{resource_name}"))
  let req_body = {"id": $id, "identity": $identity, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"headers": $headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/deleteAllCodespaces
export def "tokens-subscriptions-resource-groups-providers-plans-delete-all-codespaces create" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), provider_namespace: (encode-path-segment $provider_namespace), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/Tokens/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/{provider_namespace}/plans/{resource_name}/deleteAllCodespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/deleteAllEnvironments
export def "tokens-subscriptions-resource-groups-providers-plans-delete-all-environments create" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), provider_namespace: (encode-path-segment $provider_namespace), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/Tokens/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/{provider_namespace}/plans/{resource_name}/deleteAllEnvironments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/readAllCodespaces
export def "tokens-subscriptions-resource-groups-providers-plans-read-all-codespaces create" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), provider_namespace: (encode-path-segment $provider_namespace), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/Tokens/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/{provider_namespace}/plans/{resource_name}/readAllCodespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/readAllEnvironments
export def "tokens-subscriptions-resource-groups-providers-plans-read-all-environments create" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), provider_namespace: (encode-path-segment $provider_namespace), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/Tokens/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/{provider_namespace}/plans/{resource_name}/readAllEnvironments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/writeCodespaces
export def "tokens-subscriptions-resource-groups-providers-plans-write-codespaces create" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), provider_namespace: (encode-path-segment $provider_namespace), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/Tokens/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/{provider_namespace}/plans/{resource_name}/writeCodespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/writeDelegates
#
# --identity shape: {displayName?: string, id?: string, username?: string}
export def "tokens-subscriptions-resource-groups-providers-plans-write-delegates create" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment-ids: list<string> # nullable
  --expiration: string # nullable, format: date-time
  --identity: record # shape: {displayName?: string, id?: string, username?: string}
  --port-numbers: list<int> # nullable
  --scope: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), provider_namespace: (encode-path-segment $provider_namespace), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/Tokens/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/{provider_namespace}/plans/{resource_name}/writeDelegates"))
  let req_body = {"environmentIds": $environment_ids, "expiration": $expiration, "identity": $identity, "portNumbers": $port_numbers, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/writeEnvironments
export def "tokens-subscriptions-resource-groups-providers-plans-write-environments create" [
  subscription_id: string
  resource_group: string
  provider_namespace: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), provider_namespace: (encode-path-segment $provider_namespace), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/Tokens/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/{provider_namespace}/plans/{resource_name}/writeEnvironments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Tunnel/{environmentId}/portInfo
export def "tunnel-port-info get" [
  environment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --port-number: int # format: int32
]: nothing -> record<portVisibility: string, tunnelToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "portNumber" $port_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({environment_id: (encode-path-segment $environment_id)} | format pattern "/api/v1/Tunnel/{environment_id}/portInfo") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/UserSubscriptions
export def "user-subscriptions delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/UserSubscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/UserSubscriptions
export def "user-subscriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/UserSubscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/pools/default
export def "pools-default get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --sku-name: list<string>
]: nothing -> table<allWithLatestVersion: bool, isEnvironmentPool: bool, location: string, poolCode: string, readyUnassignedCount: int, readyUnassignedLatestVersionCount: int, readyUnassignedNotLatestVersionAndIdleCount: int, readyUnassignedNotLatestVersionCount: int, resourceType: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuName" $sku_name "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/pools/default" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/subscriptions/{subscriptionId}/providers/GitHub.Network/{resourceType}/SubscriptionLifeCycleNotification
#
# --properties shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
export def "subscriptions-providers-git-hub-network-subscription-life-cycle-notification update" [
  subscription_id: string
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
  --registration-date: string # format: date-time
  --state: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_type: (encode-path-segment $resource_type)} | format pattern "/api/v1/subscriptions/{subscription_id}/providers/GitHub.Network/{resource_type}/SubscriptionLifeCycleNotification"))
  let req_body = {"properties": $properties, "registrationDate": $registration_date, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/providers/GitHub.Network/{resourceType}/resourceReadBegin
#
# --value item shape: {id?: string, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
export def "subscriptions-providers-git-hub-network-resource-read-begin create" [
  subscription_id: string
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: list # nullable — item shape: {id?: string, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_type: (encode-path-segment $resource_type)} | format pattern "/api/v1/subscriptions/{subscription_id}/providers/GitHub.Network/{resource_type}/resourceReadBegin"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /api/v1/subscriptions/{subscriptionId}/providers/Microsoft.Codespaces/plans/SubscriptionLifeCycleNotification
#
# --properties shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
export def "subscriptions-providers-microsoft-codespaces-plans-subscription-life-cycle-notification update" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
  --registration-date: string # format: date-time
  --state: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/api/v1/subscriptions/{subscription_id}/providers/Microsoft.Codespaces/plans/SubscriptionLifeCycleNotification"))
  let req_body = {"properties": $properties, "registrationDate": $registration_date, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/providers/Microsoft.Codespaces/plans/resourceReadBegin
#
# --value item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
export def "subscriptions-providers-microsoft-codespaces-plans-resource-read-begin create" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: list # nullable — item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/api/v1/subscriptions/{subscription_id}/providers/Microsoft.Codespaces/plans/resourceReadBegin"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /api/v1/subscriptions/{subscriptionId}/providers/Microsoft.VSOnline/plans/SubscriptionLifeCycleNotification
#
# --properties shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
export def "subscriptions-providers-microsoft-vs-online-plans-subscription-life-cycle-notification update" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
  --registration-date: string # format: date-time
  --state: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/api/v1/subscriptions/{subscription_id}/providers/Microsoft.VSOnline/plans/SubscriptionLifeCycleNotification"))
  let req_body = {"properties": $properties, "registrationDate": $registration_date, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/providers/Microsoft.VSOnline/plans/resourceReadBegin
#
# --value item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
export def "subscriptions-providers-microsoft-vs-online-plans-resource-read-begin create" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: list # nullable — item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/api/v1/subscriptions/{subscription_id}/providers/Microsoft.VSOnline/plans/resourceReadBegin"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/resourceReadBegin
#
# --value item shape: {id?: string, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
export def "subscriptions-resource-groups-providers-git-hub-network-resource-read-begin create-by-subscriptionId-resourceGroup-resourceType" [
  subscription_id: string
  resource_group: string
  resource_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: list # nullable — item shape: {id?: string, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_type: (encode-path-segment $resource_type)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/GitHub.Network/{resource_type}/resourceReadBegin"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network delete" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/GitHub.Network/{resource_type}/{resource_name}"))
  let req_body = {"id": $id, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PATCH /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network update-by-subscriptionId-resourceGroup-resourceType-resourceName" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/GitHub.Network/{resource_type}/{resource_name}"))
  let req_body = {"id": $id, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network update-by-subscriptionId-resourceGroup-resourceType-resourceName-1" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/GitHub.Network/{resource_type}/{resource_name}"))
  let req_body = {"id": $id, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceCreationCompleted
export def "subscriptions-resource-groups-providers-git-hub-network-resource-creation-completed create" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/GitHub.Network/{resource_type}/{resource_name}/resourceCreationCompleted"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceCreationValidate
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network-resource-creation-validate create" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/GitHub.Network/{resource_type}/{resource_name}/resourceCreationValidate"))
  let req_body = {"id": $id, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceDeletionCompleted
export def "subscriptions-resource-groups-providers-git-hub-network-resource-deletion-completed create" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/GitHub.Network/{resource_type}/{resource_name}/resourceDeletionCompleted"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceDeletionValidate
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network-resource-deletion-validate create" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/GitHub.Network/{resource_type}/{resource_name}/resourceDeletionValidate"))
  let req_body = {"id": $id, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourcePatchCompleted
export def "subscriptions-resource-groups-providers-git-hub-network-resource-patch-completed create" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/GitHub.Network/{resource_type}/{resource_name}/resourcePatchCompleted"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourcePatchValidate
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network-resource-patch-validate create" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/GitHub.Network/{resource_type}/{resource_name}/resourcePatchValidate"))
  let req_body = {"id": $id, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceReadBegin
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network-resource-read-begin create-by-subscriptionId-resourceGroup-resourceType-resourceName" [
  subscription_id: string
  resource_group: string
  resource_type: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {subnetId?: string}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_type: (encode-path-segment $resource_type), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/GitHub.Network/{resource_type}/{resource_name}/resourceReadBegin"))
  let req_body = {"id": $id, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/resourceReadBegin
#
# --value item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-read-begin create-by-subscriptionId-resourceGroup" [
  subscription_id: string
  resource_group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: list # nullable — item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/resourceReadBegin"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans update" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --headers: record
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}"))
  let req_body = {"id": $id, "identity": $identity, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"headers": $headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/deleteAllCodespaces
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-delete-all-codespaces create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/deleteAllCodespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/deleteAllEnvironments
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-delete-all-environments create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/deleteAllEnvironments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/readAllCodespaces
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-read-all-codespaces create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/readAllCodespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/readAllEnvironments
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-read-all-environments create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/readAllEnvironments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/readDelegates
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-read-delegates create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/readDelegates"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceCreationCompleted
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-creation-completed create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/resourceCreationCompleted"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceCreationValidate
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-creation-validate create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/resourceCreationValidate"))
  let req_body = {"id": $id, "identity": $identity, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceDeletionValidate
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-deletion-validate create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/resourceDeletionValidate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourcePatchCompleted
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-patch-completed create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --headers: record
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/resourcePatchCompleted"))
  let req_body = {"identity": $identity, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"headers": $headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourcePatchValidate
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-patch-validate create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/resourcePatchValidate"))
  let req_body = {"identity": $identity, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceReadBegin
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-read-begin create-by-subscriptionId-resourceGroup-resourceName" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/resourceReadBegin"))
  let req_body = {"id": $id, "identity": $identity, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/writeCodespaces
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-write-codespaces create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/writeCodespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/writeDelegates
#
# --identity shape: {displayName?: string, id?: string, username?: string}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-write-delegates create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment-ids: list<string> # nullable
  --expiration: string # nullable, format: date-time
  --identity: record # shape: {displayName?: string, id?: string, username?: string}
  --port-numbers: list<int> # nullable
  --scope: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/writeDelegates"))
  let req_body = {"environmentIds": $environment_ids, "expiration": $expiration, "identity": $identity, "portNumbers": $port_numbers, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/writeEnvironments
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-write-environments create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/writeEnvironments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/resourceReadBegin
#
# --value item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-read-begin create-by-subscriptionId-resourceGroup" [
  subscription_id: string
  resource_group: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: list # nullable — item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/resourceReadBegin"))
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans update" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --headers: record
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}"))
  let req_body = {"id": $id, "identity": $identity, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"headers": $headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/deleteAllCodespaces
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-delete-all-codespaces create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/deleteAllCodespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/deleteAllEnvironments
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-delete-all-environments create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/deleteAllEnvironments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/readAllCodespaces
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-read-all-codespaces create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/readAllCodespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/readAllEnvironments
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-read-all-environments create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/readAllEnvironments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/readDelegates
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-read-delegates create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/readDelegates"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceCreationCompleted
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-creation-completed create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/resourceCreationCompleted"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceCreationValidate
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-creation-validate create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/resourceCreationValidate"))
  let req_body = {"id": $id, "identity": $identity, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceDeletionValidate
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-deletion-validate create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/resourceDeletionValidate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourcePatchCompleted
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-patch-completed create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --headers: record
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/resourcePatchCompleted"))
  let req_body = {"identity": $identity, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"headers": $headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourcePatchValidate
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-patch-validate create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/resourcePatchValidate"))
  let req_body = {"identity": $identity, "properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceReadBegin
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-read-begin create-by-subscriptionId-resourceGroup-resourceName" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # nullable
  --identity: record # shape: {principalId?: string, tenantId?: string, type?: string}
  --location: string # nullable
  --name: string # nullable
  --properties: record # shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
  --provisioning-state: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/resourceReadBegin"))
  let req_body = {"id": $id, "identity": $identity, "location": $location, "name": $name, "properties": $properties, "provisioningState": $provisioning_state, "tags": $tags, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/writeCodespaces
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-write-codespaces create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/writeCodespaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/writeDelegates
#
# --identity shape: {displayName?: string, id?: string, username?: string}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-write-delegates create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environment-ids: list<string> # nullable
  --expiration: string # nullable, format: date-time
  --identity: record # shape: {displayName?: string, id?: string, username?: string}
  --port-numbers: list<int> # nullable
  --scope: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/writeDelegates"))
  let req_body = {"environmentIds": $environment_ids, "expiration": $expiration, "identity": $identity, "portNumbers": $port_numbers, "scope": $scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/writeEnvironments
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-write-environments create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expiration: string # format: date-time
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expiration" $expiration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/writeEnvironments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/deleteDelegates
export def "subscriptions-providers-microsoft-codespaces-plans-delete-delegates create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/{resource_group}/providers/Microsoft.Codespaces/plans/{resource_name}/deleteDelegates"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/deleteDelegates
export def "subscriptions-providers-microsoft-vs-online-plans-delete-delegates create" [
  subscription_id: string
  resource_group: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group: (encode-path-segment $resource_group), resource_name: (encode-path-segment $resource_name)} | format pattern "/api/v1/subscriptions/{subscription_id}/{resource_group}/providers/Microsoft.VSOnline/plans/{resource_name}/deleteDelegates"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/tenant/{tenantId}/Pool/{poolName}
export def "tenant-pool delete" [
  tenant_id: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_name: (encode-path-segment $pool_name)} | format pattern "/api/v1/tenant/{tenant_id}/Pool/{pool_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/tenant/{tenantId}/Pool/{poolName}
export def "tenant-pool get" [
  tenant_id: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<domainUserCredentials: record<domain: string, organizationalUnit: string, passwordSecretIdentifier: string, userName: string>, hotPoolSettings: record<size: int>, poolGroupName: string, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, tags: record, userGroupName: string, vmSpecs: record<diskType: int, imageResourceId: string, size: string, subnetResourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_name: (encode-path-segment $pool_name)} | format pattern "/api/v1/tenant/{tenant_id}/Pool/{pool_name}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/v1/tenant/{tenantId}/Pool/{poolName}
#
# --domainUserCredentials shape: {domain: string, organizationalUnit?: string, passwordSecretIdentifier: string, userName: string}
# --hotPoolSettings shape: {size?: int}
# --vmSpecs shape: {diskType: "0 (StandardHDD)"|"1 (StandardSSD)"|"2 (PremiumSSD)", imageResourceId: string, size: string, subnetResourceId: string}
export def "tenant-pool update-by-tenantId-poolName" [
  tenant_id: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --domain-user-credentials: record # shape: {domain: string, organizationalUnit?: string, passwordSecretIdentifier: string, userName: string}
  --hot-pool-settings: record # shape: {size?: int}
  pool_group_name: string
  --tags: record # nullable
  --user-group-name: string # nullable
  vm_specs: record # shape: {diskType: "0 (StandardHDD)"|"1 (StandardSSD)"|"2 (PremiumSSD)", imageResourceId: string, size: string, subnetResourceId: string}
]: any -> record<domainUserCredentials: record<domain: string, organizationalUnit: string, passwordSecretIdentifier: string, userName: string>, hotPoolSettings: record<size: int>, poolGroupName: string, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, tags: record, userGroupName: string, vmSpecs: record<diskType: int, imageResourceId: string, size: string, subnetResourceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_name: (encode-path-segment $pool_name)} | format pattern "/api/v1/tenant/{tenant_id}/Pool/{pool_name}"))
  let req_body = {"domainUserCredentials": $domain_user_credentials, "hotPoolSettings": $hot_pool_settings, "poolGroupName": $pool_group_name, "tags": $tags, "userGroupName": $user_group_name, "vmSpecs": $vm_specs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /api/v1/tenant/{tenantId}/Pool/{poolName}
#
# --domainUserCredentials shape: {domain: string, organizationalUnit?: string, passwordSecretIdentifier: string, userName: string}
# --hotPoolSettings shape: {size?: int}
# --vmSpecs shape: {diskType: "0 (StandardHDD)"|"1 (StandardSSD)"|"2 (PremiumSSD)", imageResourceId: string, size: string, subnetResourceId: string}
export def "tenant-pool update-by-tenantId-poolName-1" [
  tenant_id: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --domain-user-credentials: record # shape: {domain: string, organizationalUnit?: string, passwordSecretIdentifier: string, userName: string}
  --hot-pool-settings: record # shape: {size?: int}
  pool_group_name: string
  --tags: record # nullable
  --user-group-name: string # nullable
  vm_specs: record # shape: {diskType: "0 (StandardHDD)"|"1 (StandardSSD)"|"2 (PremiumSSD)", imageResourceId: string, size: string, subnetResourceId: string}
]: any -> record<domainUserCredentials: record<domain: string, organizationalUnit: string, passwordSecretIdentifier: string, userName: string>, hotPoolSettings: record<size: int>, poolGroupName: string, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, tags: record, userGroupName: string, vmSpecs: record<diskType: int, imageResourceId: string, size: string, subnetResourceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_name: (encode-path-segment $pool_name)} | format pattern "/api/v1/tenant/{tenant_id}/Pool/{pool_name}"))
  let req_body = {"domainUserCredentials": $domain_user_credentials, "hotPoolSettings": $hot_pool_settings, "poolGroupName": $pool_group_name, "tags": $tags, "userGroupName": $user_group_name, "vmSpecs": $vm_specs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}
export def "tenant-pool-group delete" [
  tenant_id: string
  pool_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_group_name: (encode-path-segment $pool_group_name)} | format pattern "/api/v1/tenant/{tenant_id}/PoolGroup/{pool_group_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}
export def "tenant-pool-group get" [
  tenant_id: string
  pool_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<displayName: string, region: int, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_group_name: (encode-path-segment $pool_group_name)} | format pattern "/api/v1/tenant/{tenant_id}/PoolGroup/{pool_group_name}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}
export def "tenant-pool-group update-by-tenantId-poolGroupName" [
  tenant_id: string
  pool_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  display_name: string
  --tags: record # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_group_name: (encode-path-segment $pool_group_name)} | format pattern "/api/v1/tenant/{tenant_id}/PoolGroup/{pool_group_name}"))
  let req_body = {"displayName": $display_name, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# PUT /api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}
export def "tenant-pool-group update-by-tenantId-poolGroupName-1" [
  tenant_id: string
  pool_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  display_name: string
  region: int@region-completer # format: int32
  --tags: record # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_group_name: (encode-path-segment $pool_group_name)} | format pattern "/api/v1/tenant/{tenant_id}/PoolGroup/{pool_group_name}"))
  let req_body = {"displayName": $display_name, "region": $region, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /api/v1/tenant/{tenantId}/pool/{poolName}/Vm
export def "tenant-pool-vm list" [
  tenant_id: string
  pool_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<connection: record<connectionType: int, liveShareWorkspaceId: string>, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_name: (encode-path-segment $pool_name)} | format pattern "/api/v1/tenant/{tenant_id}/pool/{pool_name}/Vm"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}
export def "tenant-pool-vm delete" [
  tenant_id: string
  pool_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_name: (encode-path-segment $pool_name), vm_name: (encode-path-segment $vm_name)} | format pattern "/api/v1/tenant/{tenant_id}/pool/{pool_name}/Vm/{vm_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}
export def "tenant-pool-vm get" [
  tenant_id: string
  pool_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<connection: record<connectionType: int, liveShareWorkspaceId: string>, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_name: (encode-path-segment $pool_name), vm_name: (encode-path-segment $vm_name)} | format pattern "/api/v1/tenant/{tenant_id}/pool/{pool_name}/Vm/{vm_name}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}
#
# --user shape: {userPrincipalName: string}
export def "tenant-pool-vm update" [
  tenant_id: string
  pool_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  user: record # shape: {userPrincipalName: string}
]: any -> record<connection: record<connectionType: int, liveShareWorkspaceId: string>, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_name: (encode-path-segment $pool_name), vm_name: (encode-path-segment $vm_name)} | format pattern "/api/v1/tenant/{tenant_id}/pool/{pool_name}/Vm/{vm_name}"))
  let req_body = {"user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}/start
export def "tenant-pool-vm-start create" [
  tenant_id: string
  pool_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_name: (encode-path-segment $pool_name), vm_name: (encode-path-segment $vm_name)} | format pattern "/api/v1/tenant/{tenant_id}/pool/{pool_name}/Vm/{vm_name}/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}/stop
export def "tenant-pool-vm-stop create" [
  tenant_id: string
  pool_name: string
  vm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), pool_name: (encode-path-segment $pool_name), vm_name: (encode-path-segment $vm_name)} | format pattern "/api/v1/tenant/{tenant_id}/pool/{pool_name}/Vm/{vm_name}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v2/prebuilds/delete
export def "prebuilds-delete create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  branch_name: string
  --dev-container-path: string # nullable
  --prebuild-configuration-id: int # format: int64
  repo_id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/prebuilds/delete")
  let req_body = {"branchName": $branch_name, "devContainerPath": $dev_container_path, "prebuildConfigurationId": $prebuild_configuration_id, "repoId": $repo_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DELETE /api/v2/prebuilds/repository/{repoId}/branch/{branchName}
export def "prebuilds-repository-branch delete" [
  repo_id: int
  branch_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({repo_id: (encode-path-segment $repo_id), branch_name: (encode-path-segment $branch_name)} | format pattern "/api/v2/prebuilds/repository/{repo_id}/branch/{branch_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v2/prebuilds/templates
#
# --experimentalFeatures shape: {enableDynamicHttpsDetection?: bool, queueResourceAllocation?: bool, usePrebuildFastPathIfAvailable?: bool, usePrebuiltImages?: bool, useStorageV2?: bool}
# --seed shape: {cloneUrl?: string, gitConfig?: record, recurseClone?: bool, repository?: record, seedMoniker?: string, seedType?: string}
# --templateInfo shape: {container?: record, prebuildConfigurationId?: string, templateSizeInGB?: float, totalTimeSavingsInSeconds?: string, workFlowRunId?: string}
export def "prebuilds-templates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --dev-container-path: string # nullable
  --experimental-features: record # shape: {enableDynamicHttpsDetection?: bool, queueResourceAllocation?: bool, usePrebuildFastPathIfAvailable?: bool, usePrebuiltImages?: bool, useStorageV2?: bool}
  --features: record # nullable
  friendly_name: string
  --plan-id: string # nullable
  --seed: record # shape: {cloneUrl?: string, gitConfig?: record, recurseClone?: bool, repository?: record, seedMoniker?: string, seedType?: string}
  --storage-type: int@storage-type-completer # format: int32
  --template-info: record # shape: {container?: record, prebuildConfigurationId?: string, templateSizeInGB?: float, totalTimeSavingsInSeconds?: string, workFlowRunId?: string}
]: any -> record<properties: record, sasUrl: string, templateId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/prebuilds/templates")
  let req_body = {"devContainerPath": $dev_container_path, "experimentalFeatures": $experimental_features, "features": $features, "friendlyName": $friendly_name, "planId": $plan_id, "seed": $seed, "storageType": $storage_type, "templateInfo": $template_info} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /api/v2/prebuilds/templates/skus/repo/{repoId}/branch/{branchName}/hash/{prebuildHash}/location/{location}/devcontainerpath/{devContainerPath}
#
# operationId: GetPrebuildReadinessSkusRoute
export def "prebuilds-templates-skus-repo-branch-hash-location-devcontainerpath get-readiness-route" [
  repo_id: string
  branch_name: string
  prebuild_hash: string
  location: string
  dev_container_path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --storage-type: int@storage-type-completer # format: int32
  --fast-path-enabled: oneof<nothing, bool>
]: nothing -> record<branchName: string, devContainerPath: string, location: int, poolSkus: list<string>, prebuildHash: string, repoId: string, supportedSkus: list<string>, templateSkus: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storageType" $storage_type "scalar") (serialize-qp "fastPathEnabled" $fast_path_enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({repo_id: (encode-path-segment $repo_id), branch_name: (encode-path-segment $branch_name), prebuild_hash: (encode-path-segment $prebuild_hash), location: (encode-path-segment $location), dev_container_path: (encode-path-segment $dev_container_path)} | format pattern "/api/v2/prebuilds/templates/skus/repo/{repo_id}/branch/{branch_name}/hash/{prebuild_hash}/location/{location}/devcontainerpath/{dev_container_path}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v2/prebuilds/templates/updatemaxversions
export def "prebuilds-templates-updatemaxversions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  branch_name: string
  --dev-container-path: string # nullable
  max_prebuild_template_versions: int # format: int32
  repo_id: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/prebuilds/templates/updatemaxversions")
  let req_body = {"branchName": $branch_name, "devContainerPath": $dev_container_path, "maxPrebuildTemplateVersions": $max_prebuild_template_versions, "repoId": $repo_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# POST /api/v2/prebuilds/templates/{templateId}/updatestatus
export def "prebuilds-templates-updatestatus create" [
  template_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-success: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({template_id: (encode-path-segment $template_id)} | format pattern "/api/v2/prebuilds/templates/{template_id}/updatestatus"))
  let req_body = {"isSuccess": $is_success} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /health
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /internal/Netmon/correlation
export def "internal-netmon-correlation get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --mac-address: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "macAddress" $mac_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/internal/Netmon/correlation" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /tunnelauth
export def "tunnelauth get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --cluster: string
  --name: string
  --port: int # format: int32
  --pb: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "cluster" $cluster "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "port" $port "scalar") (serialize-qp "pb" $pb "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tunnelauth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /tunnelauth
export def "tunnelauth create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --op: string
  --id: string
  --cluster: string
  --name: string
  --port: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "op" $op "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "cluster" $cluster "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "port" $port "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tunnelauth" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /warmup
export def "warmup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/warmup")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
