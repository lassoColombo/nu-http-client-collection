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
def tunnelType-completer [] { ["0 (Basis)" "1 (Liveshare)"] }
def newValue-completer [] { ["0 (None)" "1 (Created)" "10 (Archived)" "11 (Starting)" "12 (ShuttingDown)" "13 (Failed)" "14 (Exporting)" "15 (Updating)" "16 (Rebuilding)" "2 (Queued)" "3 (Provisioning)" "4 (Available)" "5 (Awaiting)" "6 (Unavailable)" "7 (Deleted)" "8 (Moved)" "9 (Shutdown)"] }
def oldValue-completer [] { ["0 (None)" "1 (Created)" "10 (Archived)" "11 (Starting)" "12 (ShuttingDown)" "13 (Failed)" "14 (Exporting)" "15 (Updating)" "16 (Rebuilding)" "2 (Queued)" "3 (Provisioning)" "4 (Available)" "5 (Awaiting)" "6 (Unavailable)" "7 (Deleted)" "8 (Moved)" "9 (Shutdown)"] }
def storageType-completer [] { ["0 (V1)" "1 (V2)"] }
def location-completer [] { ["1001 (SouthAfricaNorth)" "1002 (SouthAfricaWest)" "101 (EastAsia)" "102 (SouthEastAsia)" "1201 (UaeCentral)" "1202 (UaeNorth)" "1401 (UkSouth)" "1402 (UkWest)" "1501 (CentralUs)" "1502 (EastUs)" "1503 (EastUs2)" "1504 (NorthCentralUs)" "1505 (SouthCentralUs)" "1506 (WestCentralUs)" "1507 (WestUs)" "1508 (WestUs2)" "1509 (WestUs3)" "1601 (CentralUsEuap)" "1602 (EastUs2Euap)" "1701 (SwitzerlandNorth)" "1702 (SwitzerlandWest)" "1801 (GermanyNorth)" "1802 (GermanyWestCentral)" "1901 (NorwayWest)" "1902 (NorwayEast)" "201 (AustraliaCentral)" "202 (AustraliaCentral2)" "203 (AustraliaEast)" "205 (AustraliaSouthEast)" "301 (BrazilSouth)" "401 (CanadaCentral)" "402 (CanadaEast)" "501 (NorthEurope)" "502 (WestEurope)" "601 (FranceCentral)" "602 (FranceSouth)" "701 (CentralIndia)" "702 (SouthIndia)" "703 (WestIndia)" "801 (JapanEast)" "802 (JapanWest)" "901 (KoreaCentral)" "902 (KoreaSouth)"] }
def subtype-completer [] { ["0 (Default)" "2 (ShrunkBlob)" "3 (FullBlob)" "4 (UserParametersBlob)" "5 (PrebuildHash)" "6 (VnetInjected)"] }
def type-completer [] { ["1 (ComputeVM)" "10 (VirtualNetwork)" "11 (NetworkSecurityGroup)" "12 (LiveShareWorkspace)" "13 (BasisTunnel)" "14 (StorageBlockBlob)" "15 (DataDisk)" "16 (PortForwardingWorkspace)" "2 (StorageFileShare)" "3 (StorageArchive)" "4 (KeyVault)" "5 (OSDisk)" "6 (NetworkInterface)" "7 (InputQueue)" "8 (Snapshot)" "9 (PoolQueue)"] }
def scope-completer [] { ["1 (Plan)" "2 (User)"] }
def type-completer-1 [] { ["1 (EnvironmentVariable)" "2 (ContainerRegistry)"] }
def region-completer [] { ["1001 (SouthAfricaNorth)" "1002 (SouthAfricaWest)" "101 (EastAsia)" "102 (SouthEastAsia)" "1201 (UaeCentral)" "1202 (UaeNorth)" "1401 (UkSouth)" "1402 (UkWest)" "1501 (CentralUs)" "1502 (EastUs)" "1503 (EastUs2)" "1504 (NorthCentralUs)" "1505 (SouthCentralUs)" "1506 (WestCentralUs)" "1507 (WestUs)" "1508 (WestUs2)" "1509 (WestUs3)" "1601 (CentralUsEuap)" "1602 (EastUs2Euap)" "1701 (SwitzerlandNorth)" "1702 (SwitzerlandWest)" "1801 (GermanyNorth)" "1802 (GermanyWestCentral)" "1901 (NorwayWest)" "1902 (NorwayEast)" "201 (AustraliaCentral)" "202 (AustraliaCentral2)" "203 (AustraliaEast)" "205 (AustraliaSouthEast)" "301 (BrazilSouth)" "401 (CanadaCentral)" "402 (CanadaEast)" "501 (NorthEurope)" "502 (WestEurope)" "601 (FranceCentral)" "602 (FranceSouth)" "701 (CentralIndia)" "702 (SouthIndia)" "703 (WestIndia)" "801 (JapanEast)" "802 (JapanWest)" "901 (KoreaCentral)" "902 (KoreaSouth)"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "agent-telemetry post" } } | get name | first)
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
export def "agent-telemetry post" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/AgentTelemetry/standalone
export def "agent-telemetry-standalone post" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/v1/Agents/($family)")
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
  --planId: string
  --deleted: oneof<nothing, bool> # default: false
]: nothing -> table<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list, imageAllowList: list>, seed: record<cloneUrl: string, gitConfig: record, recurseClone: bool, repository: record, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "planId" $planId "scalar") (serialize-qp "deleted" $deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Environments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Environments
#
# --billableOwner shape: {id?: string, login?: string, type?: "0 (User)"|"1 (Organization)"}
# --connection shape: {connectionServiceUri?: string, connectionSessionId?: string, connectionSessionPath?: string, hostPublicKeys?: list, relayEndpoint?: string, relaySasToken?: string, sessionToken?: string, tunnelProperties?: record}
# --experimentalFeatures shape: {enableDynamicHttpsDetection?: bool, queueResourceAllocation?: bool, usePrebuildFastPathIfAvailable?: bool, usePrebuiltImages?: bool, useStorageV2?: bool}
# --identity shape: {displayName?: string, id?: string, userName?: string}
# --netmonCorrelationData shape: {billableOwnerCreatedAt?: string, billableOwnerDatabaseId?: string, billableOwnerGlobalRelayId?: string, billableOwnerPlan?: string, ownerCreatedAt?: string, ownerDatabaseId?: string, ownerGlobalRelayId?: string, ownerPlan?: string, repositoryCreatedAt?: string, repositoryDatabaseId?: string, repositoryGlobalRelayId?: string, repositoryPrivate?: bool}
# --personalization shape: {dotfilesInstallCommand?: string, dotfilesRepository?: string, dotfilesTargetPath?: string}
# --runtimeConstraints shape: {allowedPortPrivacySettings?: list, imageAllowList?: list}
# --secrets item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
# --seed shape: {cloneUrl?: string, gitConfig?: record, recurseClone?: bool, repository?: record, seedMoniker?: string, seedType?: string}
@deprecated --flag location
@deprecated --flag platform
export def "environments post" [
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
  --analyticsTrackingId: string # nullable
  --autoShutdownDelayMinutes: int # format: int32
  --billableOwner: record # shape: {id?: string, login?: string, type?: "0 (User)"|"1 (Organization)"}
  --connection: record # shape: {connectionServiceUri?: string, connectionSessionId?: string, connectionSessionPath?: string, hostPublicKeys?: list, relayEndpoint?: string, relaySasToken?: string, sessionToken?: string, tunnelProperties?: record}
  --containerImage: string # nullable
  --createAsPrebuild: oneof<nothing, bool>
  --devContainerJson: string # nullable
  --devContainerPath: string # nullable
  --experimentalFeatures: record # shape: {enableDynamicHttpsDetection?: bool, queueResourceAllocation?: bool, usePrebuildFastPathIfAvailable?: bool, usePrebuiltImages?: bool, useStorageV2?: bool}
  --features: record # nullable
  friendlyName: string
  --gitHubApiUrl: string # nullable
  --gitHubAppUrl: string # nullable
  --gitHubPfsAuthEndpoint: string # nullable
  --githubEnvironmentEndpoint: string # nullable
  --hasDevcontainerJson: oneof<nothing, bool>
  --identity: record # shape: {displayName?: string, id?: string, userName?: string}
  --label: string # nullable
  --location: string # DEPRECATED, nullable
  --netmonCorrelationData: record # shape: {billableOwnerCreatedAt?: string, billableOwnerDatabaseId?: string, billableOwnerGlobalRelayId?: string, billableOwnerPlan?: string, ownerCreatedAt?: string, ownerDatabaseId?: string, ownerGlobalRelayId?: string, ownerPlan?: string, repositoryCreatedAt?: string, repositoryDatabaseId?: string, repositoryGlobalRelayId?: string, repositoryPrivate?: bool}
  --personalization: record # shape: {dotfilesInstallCommand?: string, dotfilesRepository?: string, dotfilesTargetPath?: string}
  --planId: string # nullable
  --platform: string # DEPRECATED, nullable
  --runtimeConstraints: record # shape: {allowedPortPrivacySettings?: list, imageAllowList?: list}
  --secrets: list # nullable — item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
  --seed: record # shape: {cloneUrl?: string, gitConfig?: record, recurseClone?: bool, repository?: record, seedMoniker?: string, seedType?: string}
  --skuName: string # nullable
  --testAccount: oneof<nothing, bool>
  type: string
  --userTier: string # nullable
  --workingDirectory: string # nullable
]: any -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access" $access "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Environments" $qp)
  let body = {analyticsTrackingId: $analyticsTrackingId, autoShutdownDelayMinutes: $autoShutdownDelayMinutes, billableOwner: $billableOwner, connection: $connection, containerImage: $containerImage, createAsPrebuild: $createAsPrebuild, devContainerJson: $devContainerJson, devContainerPath: $devContainerPath, experimentalFeatures: $experimentalFeatures, features: $features, friendlyName: $friendlyName, gitHubApiUrl: $gitHubApiUrl, gitHubAppUrl: $gitHubAppUrl, gitHubPfsAuthEndpoint: $gitHubPfsAuthEndpoint, githubEnvironmentEndpoint: $githubEnvironmentEndpoint, hasDevcontainerJson: $hasDevcontainerJson, identity: $identity, label: $label, location: $location, netmonCorrelationData: $netmonCorrelationData, personalization: $personalization, planId: $planId, platform: $platform, runtimeConstraints: $runtimeConstraints, secrets: $secrets, seed: $seed, skuName: $skuName, testAccount: $testAccount, type: $type, userTier: $userTier, workingDirectory: $workingDirectory} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/Environments/{environmentId}
export def "environments delete" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Environments/{environmentId}
#
# operationId: GetEnvironmentRoute
export def "environments GetEnvironmentRoute" [
  environmentId: string
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
  --pfConnect: oneof<nothing, bool>
  --deleted: oneof<nothing, bool> # default: false
]: nothing -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connect" $connect "scalar") (serialize-qp "pfConnect" $pfConnect "scalar") (serialize-qp "deleted" $deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/v1/Environments/{environmentId}
#
# --failoverDetails shape: {failoverEnabled?: bool, failoverRegion?: "101 (EastAsia)"|"102 (SouthEastAsia)"|"201 (AustraliaCentral)"|"202 (AustraliaCentral2)"|"203 (AustraliaEast)"|"205 (AustraliaSouthEast)"|"301 (BrazilSouth)"|"401 (CanadaCentral)"|"402 (CanadaEast)"|"501 (NorthEurope)"|"502 (WestEurope)"|"601 (FranceCentral)"|"602 (FranceSouth)"|"701 (CentralIndia)"|"702 (SouthIndia)"|"703 (WestIndia)"|"801 (JapanEast)"|"802 (JapanWest)"|"901 (KoreaCentral)"|"902 (KoreaSouth)"|"1001 (SouthAfricaNorth)"|"1002 (SouthAfricaWest)"|"1201 (UaeCentral)"|"1202 (UaeNorth)"|"1401 (UkSouth)"|"1402 (UkWest)"|"1501 (CentralUs)"|"1502 (EastUs)"|"1503 (EastUs2)"|"1504 (NorthCentralUs)"|"1505 (SouthCentralUs)"|"1506 (WestCentralUs)"|"1507 (WestUs)"|"1508 (WestUs2)"|"1509 (WestUs3)"|"1601 (CentralUsEuap)"|"1602 (EastUs2Euap)"|"1701 (SwitzerlandNorth)"|"1702 (SwitzerlandWest)"|"1801 (GermanyNorth)"|"1802 (GermanyWestCentral)"|"1901 (NorwayWest)"|"1902 (NorwayEast)"}
export def "environments patch" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --autoShutdownDelayMinutes: int # nullable, format: int32
  --failoverDetails: record # shape: {failoverEnabled?: bool, failoverRegion?: "101 (EastAsia)"|"102 (SouthEastAsia)"|"201 (AustraliaCentral)"|"202 (AustraliaCentral2)"|"203 (AustraliaEast)"|"205 (AustraliaSouthEast)"|"301 (BrazilSouth)"|"401 (CanadaCentral)"|"402 (CanadaEast)"|"501 (NorthEurope)"|"502 (WestEurope)"|"601 (FranceCentral)"|"602 (FranceSouth)"|"701 (CentralIndia)"|"702 (SouthIndia)"|"703 (WestIndia)"|"801 (JapanEast)"|"802 (JapanWest)"|"901 (KoreaCentral)"|"902 (KoreaSouth)"|"1001 (SouthAfricaNorth)"|"1002 (SouthAfricaWest)"|"1201 (UaeCentral)"|"1202 (UaeNorth)"|"1401 (UkSouth)"|"1402 (UkWest)"|"1501 (CentralUs)"|"1502 (EastUs)"|"1503 (EastUs2)"|"1504 (NorthCentralUs)"|"1505 (SouthCentralUs)"|"1506 (WestCentralUs)"|"1507 (WestUs)"|"1508 (WestUs2)"|"1509 (WestUs3)"|"1601 (CentralUsEuap)"|"1602 (EastUs2Euap)"|"1701 (SwitzerlandNorth)"|"1702 (SwitzerlandWest)"|"1801 (GermanyNorth)"|"1802 (GermanyWestCentral)"|"1901 (NorwayWest)"|"1902 (NorwayEast)"}
  --friendlyName: string # nullable
  --planAccessToken: string # nullable
  --planId: string # nullable
  --skuName: string # nullable
]: any -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)")
  let body = {autoShutdownDelayMinutes: $autoShutdownDelayMinutes, failoverDetails: $failoverDetails, friendlyName: $friendlyName, planAccessToken: $planAccessToken, planId: $planId, skuName: $skuName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/Environments/{environmentId}/_callback
#
# operationId: UpdateEnvironmentRoute
# --payload shape: {sessionId?: string, sessionPath?: string}
export def "environments-callback UpdateEnvironmentRoute" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/_callback")
  let body = {payload: $payload, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/Environments/{environmentId}/archive
export def "environments-archive get" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/archive")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Environments/{environmentId}/archive
export def "environments-archive post" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/archive")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Environments/{environmentId}/export
export def "environments-export post" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/export")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/v1/Environments/{environmentId}/folder
export def "environments-folder patch" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --recentFolderPaths: list # nullable
]: any -> record<accessToken: string, active: string, autoShutdownDelayMinutes: int, billableOwnerType: int, clientUsage: record<sessionId: string, usageData: record>, connection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, container: record<id: string, schemaVersion: string>, containerImage: string, createFromPrebuild: bool, created: string, displayStorageUtilizationInKb: bool, exportedBlobUrl: string, failoverDetails: record<failoverEnabled: bool, failoverRegion: int>, features: record, friendlyName: string, gitStatus: record<ahead: int, behind: int, branch: string, commit: string, hasUncommittedChanges: bool, hasUnpushedChanges: bool, noGitRepo: bool>, id: string, lastStateUpdateReason: string, lastUsed: string, location: string, organizationId: string, ownerId: string, planId: string, platform: string, portForwardingConnection: record<connectionServiceUri: string, connectionSessionId: string, connectionSessionPath: string, hostPublicKeys: list<string>, relayEndpoint: string, relaySasToken: string, sessionToken: string, tunnelProperties: record<clusterId: string, connectAccessToken: string, domain: string, managePortsAccessToken: string, serviceUri: string, tunnelId: string, tunnelName: string>>, prebuildType: string, recentFolders: list<string>, resourceTier: int, runtimeConstraints: record<allowedPortPrivacySettings: list<int>, imageAllowList: list<string>>, seed: record<cloneUrl: string, gitConfig: record<userEmail: string, userName: string>, recurseClone: bool, repository: record<branchName: string, commitId: string, createType: string, diskUsage: string, name: string, owner: string, prebuildHash: string, repoId: int, url: string>, seedMoniker: string, seedType: string>, skuDisplayName: string, skuName: string, state: string, storageUtilizationInKb: int, subscriptionData: record<computeQuota: int, computeUsage: int, subscriptionId: string, subscriptionState: string>, templateStatus: string, type: string, updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/folder")
  let body = {recentFolderPaths: $recentFolderPaths} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/Environments/{environmentId}/heartbeattoken
export def "environments-heartbeattoken get" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/heartbeattoken")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Environments/{environmentId}/notify
export def "environments-notify post" [
  environmentId: string
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
  --displayMode: string # nullable
  --message: string # nullable
  --modal: oneof<nothing, bool>
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/notify")
  let body = {details: $details, displayMode: $displayMode, message: $message, modal: $modal} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/Environments/{environmentId}/ports/{port}
export def "environments-ports delete" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/ports/($port)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/Environments/{environmentId}/ports/{port}
export def "environments-ports put" [
  environmentId: string
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
  --tunnelType: int@tunnelType-completer # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/ports/($port)")
  let body = {privacy: $privacy, tunnelType: $tunnelType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/Environments/{environmentId}/restore
export def "environments-restore patch" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/restore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/Environments/{environmentId}/secrets
#
# --secrets item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
export def "environments-secrets put" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/secrets")
  let body = {secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/Environments/{environmentId}/shutdown
export def "environments-shutdown post" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/shutdown")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Environments/{environmentId}/start
export def "environments-start post" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/start" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Environments/{environmentId}/state
export def "environments-state get" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/state")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Environments/{environmentId}/updates
export def "environments-updates get" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Environments/($environmentId)/updates")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/GenevaActions/Billing/resend
export def "geneva-actions-billing-resend post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --endTime: string # format: date-time
  --startTime: string # format: date-time
]: any -> record<billGenerationTime: string, environmentId: string, id: string, location: int, partitionKey: string, periodEnd: string, periodStart: string, plan: record<location: int, name: string, providerNamespace: string, resourceGroup: string, resourceId: string, subscription: string>, usage: record, usageDetail: table<endState: int, id: string, resourceUsage: record, sku: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/Billing/resend")
  let body = {endTime: $endTime, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/GenevaActions/Billing/{environmentId}
export def "geneva-actions-billing get" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --startTime: string
  --endTime: string
]: nothing -> record<billGenerationTime: string, environmentId: string, id: string, location: int, partitionKey: string, periodEnd: string, periodStart: string, plan: record<location: int, name: string, providerNamespace: string, resourceGroup: string, resourceId: string, subscription: string>, usage: record, usageDetail: table<endState: int, id: string, resourceUsage: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/GenevaActions/Billing/($environmentId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/GenevaActions/Billing/{environmentId}/state-changes
export def "geneva-actions-billing-state-changes get" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/GenevaActions/Billing/($environmentId)/state-changes")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/GenevaActions/Billing/{environmentId}/state-changes
export def "geneva-actions-billing-state-changes post" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --newValue: int@newValue-completer # format: int32
  --oldValue: int@oldValue-completer # format: int32
  --time: string # nullable, format: date-time
]: any -> record<environment: record<id: string, name: string, sku: record<name: string, tier: string>, userId: string>, id: string, newValue: int, oldValue: int, partitionKey: string, time: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/GenevaActions/Billing/($environmentId)/state-changes")
  let body = {newValue: $newValue, oldValue: $oldValue, time: $time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/GenevaActions/Configuration/{target}
export def "geneva-actions-configuration post" [
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
  let full_url = (build-url $base $"/api/v1/GenevaActions/Configuration/($target)")
  let body = {comment: $comment, key: $key, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/api/v1/GenevaActions/Configuration/($target)/($key)")
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
  let full_url = (build-url $base $"/api/v1/GenevaActions/Configuration/($target)/($key)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/GenevaActions/Environments/{environmentId}
export def "geneva-actions-environments delete" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deletionType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deletionType" $deletionType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/GenevaActions/Environments/($environmentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/GenevaActions/Environments/{environmentId}
export def "geneva-actions-environments get" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/GenevaActions/Environments/($environmentId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/GenevaActions/Environments/{environmentId}/archive
export def "geneva-actions-environments-archive put" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/GenevaActions/Environments/($environmentId)/archive")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/GenevaActions/Environments/{environmentId}/archived_storage_sas/{targetBlob}
export def "geneva-actions-environments-archived-storage-sas get" [
  environmentId: string
  targetBlob: string
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
  let full_url = (build-url $base $"/api/v1/GenevaActions/Environments/($environmentId)/archived_storage_sas/($targetBlob)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/GenevaActions/Environments/{environmentId}/shutdown
export def "geneva-actions-environments-shutdown put" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/GenevaActions/Environments/($environmentId)/shutdown")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/GenevaActions/Environments/{environmentId}/upload/running/vm/logs
export def "geneva-actions-environments-upload-running-vm-logs post" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/GenevaActions/Environments/($environmentId)/upload/running/vm/logs")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/GenevaActions/Pools/change-resource-deletion-setting
export def "geneva-actions-pools-change-resource-deletion-setting post" [
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
  --poolCode: string # nullable
  --poolType: string # nullable
  --region: string # nullable
]: any -> record<comment: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/Pools/change-resource-deletion-setting")
  let body = {comment: $comment, enabled: $enabled, poolCode: $poolCode, poolType: $poolType, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/GenevaActions/Pools/{poolCode}/rotate-pool
export def "geneva-actions-pools-rotate-pool post" [
  poolCode: string
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
  let full_url = (build-url $base $"/api/v1/GenevaActions/Pools/($poolCode)/rotate-pool")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/GenevaActions/Pools/{target}
export def "geneva-actions-pools post" [
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
  --maxTargetCount: string # nullable
  --minTargetCount: string # nullable
  --poolCode: string # nullable
  --poolType: string # nullable
  --region: string # nullable
  --targetCount: string # nullable
]: any -> record<comment: string, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/GenevaActions/Pools/($target)")
  let body = {comment: $comment, maxTargetCount: $maxTargetCount, minTargetCount: $minTargetCount, poolCode: $poolCode, poolType: $poolType, region: $region, targetCount: $targetCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/GenevaActions/Prebuilds/pools/createorupdatesettings
#
# --pools item shape: {poolType?: "0 (None)"|"1 (Blob)"|"2 (CodespacePool)"|"3 (StoragePool)"|"4 (CodespaceAndStoragePool)", skuName?: string, targetCount?: int}
export def "geneva-actions-prebuilds-pools-createorupdatesettings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branchName: string # nullable
  --devContainerPath: string # nullable
  --pools: list # nullable — item shape: {poolType?: "0 (None)"|"1 (Blob)"|"2 (CodespacePool)"|"3 (StoragePool)"|"4 (CodespaceAndStoragePool)", skuName?: string, targetCount?: int}
  --repoId: string # nullable
  --storageType: int@storageType-completer # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/Prebuilds/pools/createorupdatesettings")
  let body = {branchName: $branchName, devContainerPath: $devContainerPath, pools: $pools, repoId: $repoId, storageType: $storageType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/GenevaActions/Prebuilds/pools/delete
#
# --pools item shape: {poolType?: "0 (None)"|"1 (Blob)"|"2 (CodespacePool)"|"3 (StoragePool)"|"4 (CodespaceAndStoragePool)", skuName?: string, targetCount?: int}
export def "geneva-actions-prebuilds-pools-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --branchName: string # nullable
  --devContainerPath: string # nullable
  --pools: list # nullable — item shape: {poolType?: "0 (None)"|"1 (Blob)"|"2 (CodespacePool)"|"3 (StoragePool)"|"4 (CodespaceAndStoragePool)", skuName?: string, targetCount?: int}
  --repoId: string # nullable
  --storageType: int@storageType-completer # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/Prebuilds/pools/delete")
  let body = {branchName: $branchName, devContainerPath: $devContainerPath, pools: $pools, repoId: $repoId, storageType: $storageType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/GenevaActions/Privacy/refresh-profile-telemetry-properties
export def "geneva-actions-privacy-refresh-profile-telemetry-properties post" [
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
  --tenantId: string # nullable
  --userIds: string # nullable
]: any -> record<failed: table<oid: string, provider: string, tid: string>, succeeded: table<oid: string, provider: string, tid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/Privacy/refresh-profile-telemetry-properties")
  let body = {partner: $partner, tenantId: $tenantId, userIds: $userIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/GenevaActions/Resources/{resourceId}/under-investigation
export def "geneva-actions-resources-under-investigation post" [
  resourceId: string
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
  let full_url = (build-url $base $"/api/v1/GenevaActions/Resources/($resourceId)/under-investigation")
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
  --isEnabled: oneof<nothing, bool>
  location: int@location-completer # format: int32
  --logicalSkus: list # nullable
  subtype: int@subtype-completer # format: int32
  targetCount: int # format: int32
  type: int@type-completer # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/VnetPoolDefinitions")
  let body = {dimensions: $dimensions, isEnabled: $isEnabled, location: $location, logicalSkus: $logicalSkus, subtype: $subtype, targetCount: $targetCount, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/GenevaActions/VnetPoolDefinitions
export def "geneva-actions-vnet-pool-definitions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  dimensions: record
  --isEnabled: oneof<nothing, bool>
  location: int@location-completer # format: int32
  --logicalSkus: list # nullable
  subtype: int@subtype-completer # format: int32
  targetCount: int # format: int32
  type: int@type-completer # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/GenevaActions/VnetPoolDefinitions")
  let body = {dimensions: $dimensions, isEnabled: $isEnabled, location: $location, logicalSkus: $logicalSkus, subtype: $subtype, targetCount: $targetCount, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/HeartBeat
#
# --collectedDataList item shape: {environmentId?: string, name?: string, parentActivityId?: string, timestamp?: string}
export def "heart-beat post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agentVersion: string # nullable
  --collectedDataList: list # nullable — item shape: {environmentId?: string, name?: string, parentActivityId?: string, timestamp?: string}
  --environmentId: string # nullable
  --resourceId: string # format: uuid
  --timeStamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/HeartBeat")
  let body = {agentVersion: $agentVersion, collectedDataList: $collectedDataList, environmentId: $environmentId, resourceId: $resourceId, timeStamp: $timeStamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --planId: string
]: nothing -> record<skus: table<availableSettings: record, displayName: string, name: string, os: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $planId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/Locations/($location)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Prebuilds/pools/{poolId}/instances
#
# --environmentOptions shape: {correlationId?: string}
# --secrets item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
export def "prebuilds-pools-instances post" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environmentOptions: record # shape: {correlationId?: string}
  --secrets: list # nullable — item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Prebuilds/pools/($poolId)/instances")
  let body = {environmentOptions: $environmentOptions, secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/Prebuilds/pools/{poolId}/instances
#
# --environmentOptions shape: {correlationId?: string}
# --secrets item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
export def "prebuilds-pools-instances put" [
  poolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environmentOptions: record # shape: {correlationId?: string}
  --secrets: list # nullable — item shape: {name?: string, type?: "1 (EnvironmentVariable)"|"2 (ContainerRegistry)", value?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Prebuilds/pools/($poolId)/instances")
  let body = {environmentOptions: $environmentOptions, secrets: $secrets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/Prebuilds/template/{environmentId}
#
# operationId: GetTemplateInfoRoute
export def "prebuilds-template GetTemplateInfoRoute" [
  environmentId: string
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
  let full_url = (build-url $base $"/api/v1/Prebuilds/template/($environmentId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Prebuilds/templates/repo/{repoId}/branch/{branchName}/hash/{prebuildHash}/location/{location}/skus
#
# operationId: GetPrebuildReadinessRoute
export def "prebuilds-templates-repo-branch-hash-location-skus GetPrebuildReadinessRoute" [
  repoId: string
  branchName: string
  prebuildHash: string
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
  --storageType: int@storageType-completer # format: int32
]: nothing -> record<branchName: string, devContainerPath: string, location: int, poolSkus: list<string>, prebuildHash: string, repoId: string, supportedSkus: list<string>, templateSkus: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storageType" $storageType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/Prebuilds/templates/repo/($repoId)/branch/($branchName)/hash/($prebuildHash)/location/($location)/skus" $qp)
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
  --planId: string
]: nothing -> table<filters: list<record>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $planId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Secrets" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Secrets
#
# --filters item shape: {type?: "1 (GitRepo)"|"2 (CodespaceName)", value?: string}
export def "secrets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --planId: string
  --filters: list # nullable — item shape: {type?: "1 (GitRepo)"|"2 (CodespaceName)", value?: string}
  --notes: string # nullable
  --scope: int@scope-completer # format: int32
  --secretName: string # nullable
  --type: int@type-completer-1 # format: int32
  --value: string # nullable
]: any -> record<filters: table<type: int, value: string>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $planId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/Secrets" $qp)
  let body = {filters: $filters, notes: $notes, scope: $scope, secretName: $secretName, type: $type, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/Secrets/{secretId}
export def "secrets delete" [
  secretId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --planId: string
  --scope: int@scope-completer # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $planId "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/Secrets/($secretId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/Secrets/{secretId}
#
# --filters item shape: {type?: "1 (GitRepo)"|"2 (CodespaceName)", value?: string}
export def "secrets put" [
  secretId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --planId: string
  --filters: list # nullable — item shape: {type?: "1 (GitRepo)"|"2 (CodespaceName)", value?: string}
  --notes: string # nullable
  --scope: int@scope-completer # format: int32
  --secretName: string # nullable
  --value: string # nullable
]: any -> record<filters: table<type: int, value: string>, id: string, lastModified: string, notes: string, scope: int, secretName: string, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planId" $planId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/Secrets/($secretId)" $qp)
  let body = {filters: $filters, notes: $notes, scope: $scope, secretName: $secretName, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/Tenant/{tenantId}
export def "tenant delete" [
  tenantId: string
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
  let full_url = (build-url $base $"/api/v1/Tenant/($tenantId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Tenant/{tenantId}
export def "tenant get" [
  tenantId: string
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
  let full_url = (build-url $base $"/api/v1/Tenant/($tenantId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/Tenant/{tenantId}
export def "tenant put" [
  tenantId: string
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
  let full_url = (build-url $base $"/api/v1/Tenant/($tenantId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/plans/{planName}/deleteAllCodespaces
export def "tokens-plans-delete-all-codespaces post" [
  planName: string
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
  let full_url = (build-url $base $"/api/v1/Tokens/plans/($planName)/deleteAllCodespaces" $qp)
  let extra_headers = {"x-subscription-id": $x_subscription_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/plans/{planName}/readAllCodespaces
export def "tokens-plans-read-all-codespaces post" [
  planName: string
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
  let full_url = (build-url $base $"/api/v1/Tokens/plans/($planName)/readAllCodespaces" $qp)
  let extra_headers = {"x-subscription-id": $x_subscription_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/plans/{planName}/writeCodespaces
export def "tokens-plans-write-codespaces post" [
  planName: string
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
  let full_url = (build-url $base $"/api/v1/Tokens/plans/($planName)/writeCodespaces" $qp)
  let extra_headers = {"x-subscription-id": $x_subscription_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/plans/{planName}/writeDelegates
#
# --identity shape: {displayName?: string, id?: string, username?: string}
export def "tokens-plans-write-delegates post" [
  planName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-subscription-id: string
  --environmentIds: list # nullable
  --expiration: string # nullable, format: date-time
  --identity: record # shape: {displayName?: string, id?: string, username?: string}
  --portNumbers: list # nullable
  --scope: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Tokens/plans/($planName)/writeDelegates")
  let body = {environmentIds: $environmentIds, expiration: $expiration, identity: $identity, portNumbers: $portNumbers, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-subscription-id": $x_subscription_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "tokens-subscriptions-resource-groups-providers-plans put" [
  subscriptionId: string
  resourceGroup: string
  providerNamespace: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Tokens/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/($providerNamespace)/plans/($resourceName)")
  let body = {id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"headers": $headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/deleteAllCodespaces
export def "tokens-subscriptions-resource-groups-providers-plans-delete-all-codespaces post" [
  subscriptionId: string
  resourceGroup: string
  providerNamespace: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/Tokens/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/($providerNamespace)/plans/($resourceName)/deleteAllCodespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/deleteAllEnvironments
export def "tokens-subscriptions-resource-groups-providers-plans-delete-all-environments post" [
  subscriptionId: string
  resourceGroup: string
  providerNamespace: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/Tokens/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/($providerNamespace)/plans/($resourceName)/deleteAllEnvironments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/readAllCodespaces
export def "tokens-subscriptions-resource-groups-providers-plans-read-all-codespaces post" [
  subscriptionId: string
  resourceGroup: string
  providerNamespace: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/Tokens/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/($providerNamespace)/plans/($resourceName)/readAllCodespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/readAllEnvironments
export def "tokens-subscriptions-resource-groups-providers-plans-read-all-environments post" [
  subscriptionId: string
  resourceGroup: string
  providerNamespace: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/Tokens/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/($providerNamespace)/plans/($resourceName)/readAllEnvironments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/writeCodespaces
export def "tokens-subscriptions-resource-groups-providers-plans-write-codespaces post" [
  subscriptionId: string
  resourceGroup: string
  providerNamespace: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/Tokens/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/($providerNamespace)/plans/($resourceName)/writeCodespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/writeDelegates
#
# --identity shape: {displayName?: string, id?: string, username?: string}
export def "tokens-subscriptions-resource-groups-providers-plans-write-delegates post" [
  subscriptionId: string
  resourceGroup: string
  providerNamespace: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environmentIds: list # nullable
  --expiration: string # nullable, format: date-time
  --identity: record # shape: {displayName?: string, id?: string, username?: string}
  --portNumbers: list # nullable
  --scope: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/Tokens/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/($providerNamespace)/plans/($resourceName)/writeDelegates")
  let body = {environmentIds: $environmentIds, expiration: $expiration, identity: $identity, portNumbers: $portNumbers, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/Tokens/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/{providerNamespace}/plans/{resourceName}/writeEnvironments
export def "tokens-subscriptions-resource-groups-providers-plans-write-environments post" [
  subscriptionId: string
  resourceGroup: string
  providerNamespace: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/Tokens/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/($providerNamespace)/plans/($resourceName)/writeEnvironments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/Tunnel/{environmentId}/portInfo
export def "tunnel-port-info get" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --portNumber: int # format: int32
]: nothing -> record<portVisibility: string, tunnelToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "portNumber" $portNumber "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/Tunnel/($environmentId)/portInfo" $qp)
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
export def "user-subscriptions post" [
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
  --skuName: list
]: nothing -> table<allWithLatestVersion: bool, isEnvironmentPool: bool, location: string, poolCode: string, readyUnassignedCount: int, readyUnassignedLatestVersionCount: int, readyUnassignedNotLatestVersionAndIdleCount: int, readyUnassignedNotLatestVersionCount: int, resourceType: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuName" $skuName "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/pools/default" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/subscriptions/{subscriptionId}/providers/GitHub.Network/{resourceType}/SubscriptionLifeCycleNotification
#
# --properties shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
export def "subscriptions-providers-git-hub-network-subscription-life-cycle-notification put" [
  subscriptionId: string
  resourceType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
  --registrationDate: string # format: date-time
  --state: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/providers/GitHub.Network/($resourceType)/SubscriptionLifeCycleNotification")
  let body = {properties: $properties, registrationDate: $registrationDate, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/providers/GitHub.Network/{resourceType}/resourceReadBegin
#
# --value item shape: {id?: string, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
export def "subscriptions-providers-git-hub-network-resource-read-begin post" [
  subscriptionId: string
  resourceType: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/providers/GitHub.Network/($resourceType)/resourceReadBegin")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/subscriptions/{subscriptionId}/providers/Microsoft.Codespaces/plans/SubscriptionLifeCycleNotification
#
# --properties shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
export def "subscriptions-providers-microsoft-codespaces-plans-subscription-life-cycle-notification put" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
  --registrationDate: string # format: date-time
  --state: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/providers/Microsoft.Codespaces/plans/SubscriptionLifeCycleNotification")
  let body = {properties: $properties, registrationDate: $registrationDate, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/providers/Microsoft.Codespaces/plans/resourceReadBegin
#
# --value item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
export def "subscriptions-providers-microsoft-codespaces-plans-resource-read-begin post" [
  subscriptionId: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/providers/Microsoft.Codespaces/plans/resourceReadBegin")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/subscriptions/{subscriptionId}/providers/Microsoft.VSOnline/plans/SubscriptionLifeCycleNotification
#
# --properties shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
export def "subscriptions-providers-microsoft-vs-online-plans-subscription-life-cycle-notification put" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --properties: record # shape: {accountOwner?: record, additionalProperties?: record, locationPlacementId?: string, managedByTenants?: list, quotaId?: string, registeredFeatures?: list, tenantId?: string}
  --registrationDate: string # format: date-time
  --state: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/providers/Microsoft.VSOnline/plans/SubscriptionLifeCycleNotification")
  let body = {properties: $properties, registrationDate: $registrationDate, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/providers/Microsoft.VSOnline/plans/resourceReadBegin
#
# --value item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
export def "subscriptions-providers-microsoft-vs-online-plans-resource-read-begin post" [
  subscriptionId: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/providers/Microsoft.VSOnline/plans/resourceReadBegin")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/resourceReadBegin
#
# --value item shape: {id?: string, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
export def "subscriptions-resource-groups-providers-git-hub-network-resource-read-begin post-by-subscriptionId-resourceGroup-resourceType" [
  subscriptionId: string
  resourceGroup: string
  resourceType: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/GitHub.Network/($resourceType)/resourceReadBegin")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network delete" [
  subscriptionId: string
  resourceGroup: string
  resourceType: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/GitHub.Network/($resourceType)/($resourceName)")
  let body = {id: $id, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PATCH /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network patch" [
  subscriptionId: string
  resourceGroup: string
  resourceType: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/GitHub.Network/($resourceType)/($resourceName)")
  let body = {id: $id, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network put" [
  subscriptionId: string
  resourceGroup: string
  resourceType: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/GitHub.Network/($resourceType)/($resourceName)")
  let body = {id: $id, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceCreationCompleted
export def "subscriptions-resource-groups-providers-git-hub-network-resource-creation-completed post" [
  subscriptionId: string
  resourceGroup: string
  resourceType: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/GitHub.Network/($resourceType)/($resourceName)/resourceCreationCompleted")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceCreationValidate
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network-resource-creation-validate post" [
  subscriptionId: string
  resourceGroup: string
  resourceType: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/GitHub.Network/($resourceType)/($resourceName)/resourceCreationValidate")
  let body = {id: $id, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceDeletionCompleted
export def "subscriptions-resource-groups-providers-git-hub-network-resource-deletion-completed post" [
  subscriptionId: string
  resourceGroup: string
  resourceType: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/GitHub.Network/($resourceType)/($resourceName)/resourceDeletionCompleted")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceDeletionValidate
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network-resource-deletion-validate post" [
  subscriptionId: string
  resourceGroup: string
  resourceType: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/GitHub.Network/($resourceType)/($resourceName)/resourceDeletionValidate")
  let body = {id: $id, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourcePatchCompleted
export def "subscriptions-resource-groups-providers-git-hub-network-resource-patch-completed post" [
  subscriptionId: string
  resourceGroup: string
  resourceType: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/GitHub.Network/($resourceType)/($resourceName)/resourcePatchCompleted")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourcePatchValidate
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network-resource-patch-validate post" [
  subscriptionId: string
  resourceGroup: string
  resourceType: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/GitHub.Network/($resourceType)/($resourceName)/resourcePatchValidate")
  let body = {id: $id, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/GitHub.Network/{resourceType}/{resourceName}/resourceReadBegin
#
# --properties shape: {subnetId?: string}
export def "subscriptions-resource-groups-providers-git-hub-network-resource-read-begin post-by-subscriptionId-resourceGroup-resourceType-resourceName" [
  subscriptionId: string
  resourceGroup: string
  resourceType: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/GitHub.Network/($resourceType)/($resourceName)/resourceReadBegin")
  let body = {id: $id, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/resourceReadBegin
#
# --value item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-read-begin post-by-subscriptionId-resourceGroup" [
  subscriptionId: string
  resourceGroup: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/resourceReadBegin")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans put" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)")
  let body = {id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"headers": $headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/deleteAllCodespaces
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-delete-all-codespaces post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/deleteAllCodespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/deleteAllEnvironments
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-delete-all-environments post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/deleteAllEnvironments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/readAllCodespaces
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-read-all-codespaces post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/readAllCodespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/readAllEnvironments
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-read-all-environments post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/readAllEnvironments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/readDelegates
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-read-delegates post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/readDelegates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceCreationCompleted
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-creation-completed post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/resourceCreationCompleted")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceCreationValidate
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-creation-validate post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/resourceCreationValidate")
  let body = {id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceDeletionValidate
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-deletion-validate post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/resourceDeletionValidate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourcePatchCompleted
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-patch-completed post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/resourcePatchCompleted")
  let body = {identity: $identity, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"headers": $headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourcePatchValidate
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-patch-validate post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/resourcePatchValidate")
  let body = {identity: $identity, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/resourceReadBegin
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-resource-read-begin post-by-subscriptionId-resourceGroup-resourceName" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/resourceReadBegin")
  let body = {id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/writeCodespaces
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-write-codespaces post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/writeCodespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/writeDelegates
#
# --identity shape: {displayName?: string, id?: string, username?: string}
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-write-delegates post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environmentIds: list # nullable
  --expiration: string # nullable, format: date-time
  --identity: record # shape: {displayName?: string, id?: string, username?: string}
  --portNumbers: list # nullable
  --scope: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/writeDelegates")
  let body = {environmentIds: $environmentIds, expiration: $expiration, identity: $identity, portNumbers: $portNumbers, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/writeEnvironments
export def "subscriptions-resource-groups-providers-microsoft-codespaces-plans-write-environments post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/writeEnvironments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/resourceReadBegin
#
# --value item shape: {id?: string, identity?: record, location?: string, name?: string, properties?: record, provisioningState?: string, tags?: record, type?: string}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-read-begin post-by-subscriptionId-resourceGroup" [
  subscriptionId: string
  resourceGroup: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/resourceReadBegin")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans put" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)")
  let body = {id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"headers": $headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/deleteAllCodespaces
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-delete-all-codespaces post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/deleteAllCodespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/deleteAllEnvironments
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-delete-all-environments post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/deleteAllEnvironments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/readAllCodespaces
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-read-all-codespaces post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/readAllCodespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/readAllEnvironments
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-read-all-environments post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/readAllEnvironments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/readDelegates
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-read-delegates post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/readDelegates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceCreationCompleted
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-creation-completed post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/resourceCreationCompleted")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceCreationValidate
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-creation-validate post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/resourceCreationValidate")
  let body = {id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceDeletionValidate
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-deletion-validate post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/resourceDeletionValidate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourcePatchCompleted
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-patch-completed post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/resourcePatchCompleted")
  let body = {identity: $identity, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"headers": $headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourcePatchValidate
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-patch-validate post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/resourcePatchValidate")
  let body = {identity: $identity, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/resourceReadBegin
#
# --identity shape: {principalId?: string, tenantId?: string, type?: string}
# --properties shape: {defaultCodespaceSku?: string, defaultEnvironmentSku?: string, encryption?: record, userId?: string, vnetProperties?: record}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-resource-read-begin post-by-subscriptionId-resourceGroup-resourceName" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  --provisioningState: string # nullable
  --tags: record # nullable
  --type: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/resourceReadBegin")
  let body = {id: $id, identity: $identity, location: $location, name: $name, properties: $properties, provisioningState: $provisioningState, tags: $tags, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/writeCodespaces
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-write-codespaces post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/writeCodespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/writeDelegates
#
# --identity shape: {displayName?: string, id?: string, username?: string}
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-write-delegates post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --environmentIds: list # nullable
  --expiration: string # nullable, format: date-time
  --identity: record # shape: {displayName?: string, id?: string, username?: string}
  --portNumbers: list # nullable
  --scope: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/writeDelegates")
  let body = {environmentIds: $environmentIds, expiration: $expiration, identity: $identity, portNumbers: $portNumbers, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/subscriptions/{subscriptionId}/resourceGroups/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/writeEnvironments
export def "subscriptions-resource-groups-providers-microsoft-vs-online-plans-write-environments post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/resourceGroups/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/writeEnvironments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/{resourceGroup}/providers/Microsoft.Codespaces/plans/{resourceName}/deleteDelegates
export def "subscriptions-providers-microsoft-codespaces-plans-delete-delegates post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/($resourceGroup)/providers/Microsoft.Codespaces/plans/($resourceName)/deleteDelegates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/subscriptions/{subscriptionId}/{resourceGroup}/providers/Microsoft.VSOnline/plans/{resourceName}/deleteDelegates
export def "subscriptions-providers-microsoft-vs-online-plans-delete-delegates post" [
  subscriptionId: string
  resourceGroup: string
  resourceName: string
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
  let full_url = (build-url $base $"/api/v1/subscriptions/($subscriptionId)/($resourceGroup)/providers/Microsoft.VSOnline/plans/($resourceName)/deleteDelegates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/tenant/{tenantId}/Pool/{poolName}
export def "tenant-pool delete" [
  tenantId: string
  poolName: string
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
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/Pool/($poolName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/tenant/{tenantId}/Pool/{poolName}
export def "tenant-pool get" [
  tenantId: string
  poolName: string
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
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/Pool/($poolName)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/v1/tenant/{tenantId}/Pool/{poolName}
#
# --domainUserCredentials shape: {domain: string, organizationalUnit?: string, passwordSecretIdentifier: string, userName: string}
# --hotPoolSettings shape: {size?: int}
# --vmSpecs shape: {diskType: "0 (StandardHDD)"|"1 (StandardSSD)"|"2 (PremiumSSD)", imageResourceId: string, size: string, subnetResourceId: string}
export def "tenant-pool patch" [
  tenantId: string
  poolName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --domainUserCredentials: record # shape: {domain: string, organizationalUnit?: string, passwordSecretIdentifier: string, userName: string}
  --hotPoolSettings: record # shape: {size?: int}
  poolGroupName: string
  --tags: record # nullable
  --userGroupName: string # nullable
  vmSpecs: record # shape: {diskType: "0 (StandardHDD)"|"1 (StandardSSD)"|"2 (PremiumSSD)", imageResourceId: string, size: string, subnetResourceId: string}
]: any -> record<domainUserCredentials: record<domain: string, organizationalUnit: string, passwordSecretIdentifier: string, userName: string>, hotPoolSettings: record<size: int>, poolGroupName: string, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, tags: record, userGroupName: string, vmSpecs: record<diskType: int, imageResourceId: string, size: string, subnetResourceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/Pool/($poolName)")
  let body = {domainUserCredentials: $domainUserCredentials, hotPoolSettings: $hotPoolSettings, poolGroupName: $poolGroupName, tags: $tags, userGroupName: $userGroupName, vmSpecs: $vmSpecs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/tenant/{tenantId}/Pool/{poolName}
#
# --domainUserCredentials shape: {domain: string, organizationalUnit?: string, passwordSecretIdentifier: string, userName: string}
# --hotPoolSettings shape: {size?: int}
# --vmSpecs shape: {diskType: "0 (StandardHDD)"|"1 (StandardSSD)"|"2 (PremiumSSD)", imageResourceId: string, size: string, subnetResourceId: string}
export def "tenant-pool put" [
  tenantId: string
  poolName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --domainUserCredentials: record # shape: {domain: string, organizationalUnit?: string, passwordSecretIdentifier: string, userName: string}
  --hotPoolSettings: record # shape: {size?: int}
  poolGroupName: string
  --tags: record # nullable
  --userGroupName: string # nullable
  vmSpecs: record # shape: {diskType: "0 (StandardHDD)"|"1 (StandardSSD)"|"2 (PremiumSSD)", imageResourceId: string, size: string, subnetResourceId: string}
]: any -> record<domainUserCredentials: record<domain: string, organizationalUnit: string, passwordSecretIdentifier: string, userName: string>, hotPoolSettings: record<size: int>, poolGroupName: string, provisioningStatus: record<completedSteps: int, currentStepDescription: string, isReady: bool, operationStartedTimeUtc: string, totalSteps: int>, tags: record, userGroupName: string, vmSpecs: record<diskType: int, imageResourceId: string, size: string, subnetResourceId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/Pool/($poolName)")
  let body = {domainUserCredentials: $domainUserCredentials, hotPoolSettings: $hotPoolSettings, poolGroupName: $poolGroupName, tags: $tags, userGroupName: $userGroupName, vmSpecs: $vmSpecs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}
export def "tenant-pool-group delete" [
  tenantId: string
  poolGroupName: string
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
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/PoolGroup/($poolGroupName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}
export def "tenant-pool-group get" [
  tenantId: string
  poolGroupName: string
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
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/PoolGroup/($poolGroupName)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}
export def "tenant-pool-group patch" [
  tenantId: string
  poolGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  displayName: string
  --tags: record # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/PoolGroup/($poolGroupName)")
  let body = {displayName: $displayName, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# PUT /api/v1/tenant/{tenantId}/PoolGroup/{poolGroupName}
export def "tenant-pool-group put" [
  tenantId: string
  poolGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  displayName: string
  region: int@region-completer # format: int32
  --tags: record # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/PoolGroup/($poolGroupName)")
  let body = {displayName: $displayName, region: $region, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v1/tenant/{tenantId}/pool/{poolName}/Vm
export def "tenant-pool-vm list" [
  tenantId: string
  poolName: string
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
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/pool/($poolName)/Vm")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}
export def "tenant-pool-vm delete" [
  tenantId: string
  poolName: string
  vmName: string
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
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/pool/($poolName)/Vm/($vmName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}
export def "tenant-pool-vm get" [
  tenantId: string
  poolName: string
  vmName: string
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
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/pool/($poolName)/Vm/($vmName)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}
#
# --user shape: {userPrincipalName: string}
export def "tenant-pool-vm put" [
  tenantId: string
  poolName: string
  vmName: string
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
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/pool/($poolName)/Vm/($vmName)")
  let body = {user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}/start
export def "tenant-pool-vm-start post" [
  tenantId: string
  poolName: string
  vmName: string
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
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/pool/($poolName)/Vm/($vmName)/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v1/tenant/{tenantId}/pool/{poolName}/Vm/{vmName}/stop
export def "tenant-pool-vm-stop post" [
  tenantId: string
  poolName: string
  vmName: string
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
  let full_url = (build-url $base $"/api/v1/tenant/($tenantId)/pool/($poolName)/Vm/($vmName)/stop")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v2/prebuilds/delete
export def "prebuilds-delete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  branchName: string
  --devContainerPath: string # nullable
  --prebuildConfigurationId: int # format: int64
  repoId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/prebuilds/delete")
  let body = {branchName: $branchName, devContainerPath: $devContainerPath, prebuildConfigurationId: $prebuildConfigurationId, repoId: $repoId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /api/v2/prebuilds/repository/{repoId}/branch/{branchName}
export def "prebuilds-repository-branch delete" [
  repoId: int
  branchName: string
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
  let full_url = (build-url $base $"/api/v2/prebuilds/repository/($repoId)/branch/($branchName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v2/prebuilds/templates
#
# --experimentalFeatures shape: {enableDynamicHttpsDetection?: bool, queueResourceAllocation?: bool, usePrebuildFastPathIfAvailable?: bool, usePrebuiltImages?: bool, useStorageV2?: bool}
# --seed shape: {cloneUrl?: string, gitConfig?: record, recurseClone?: bool, repository?: record, seedMoniker?: string, seedType?: string}
# --templateInfo shape: {container?: record, prebuildConfigurationId?: string, templateSizeInGB?: float, totalTimeSavingsInSeconds?: string, workFlowRunId?: string}
export def "prebuilds-templates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --devContainerPath: string # nullable
  --experimentalFeatures: record # shape: {enableDynamicHttpsDetection?: bool, queueResourceAllocation?: bool, usePrebuildFastPathIfAvailable?: bool, usePrebuiltImages?: bool, useStorageV2?: bool}
  --features: record # nullable
  friendlyName: string
  --planId: string # nullable
  --seed: record # shape: {cloneUrl?: string, gitConfig?: record, recurseClone?: bool, repository?: record, seedMoniker?: string, seedType?: string}
  --storageType: int@storageType-completer # format: int32
  --templateInfo: record # shape: {container?: record, prebuildConfigurationId?: string, templateSizeInGB?: float, totalTimeSavingsInSeconds?: string, workFlowRunId?: string}
]: any -> record<properties: record, sasUrl: string, templateId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/prebuilds/templates")
  let body = {devContainerPath: $devContainerPath, experimentalFeatures: $experimentalFeatures, features: $features, friendlyName: $friendlyName, planId: $planId, seed: $seed, storageType: $storageType, templateInfo: $templateInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /api/v2/prebuilds/templates/skus/repo/{repoId}/branch/{branchName}/hash/{prebuildHash}/location/{location}/devcontainerpath/{devContainerPath}
#
# operationId: GetPrebuildReadinessSkusRoute
export def "prebuilds-templates-skus-repo-branch-hash-location-devcontainerpath GetPrebuildReadinessSkusRoute" [
  repoId: string
  branchName: string
  prebuildHash: string
  location: string
  devContainerPath: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --storageType: int@storageType-completer # format: int32
  --fastPathEnabled: oneof<nothing, bool>
]: nothing -> record<branchName: string, devContainerPath: string, location: int, poolSkus: list<string>, prebuildHash: string, repoId: string, supportedSkus: list<string>, templateSkus: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storageType" $storageType "scalar") (serialize-qp "fastPathEnabled" $fastPathEnabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/prebuilds/templates/skus/repo/($repoId)/branch/($branchName)/hash/($prebuildHash)/location/($location)/devcontainerpath/($devContainerPath)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /api/v2/prebuilds/templates/updatemaxversions
export def "prebuilds-templates-updatemaxversions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  branchName: string
  --devContainerPath: string # nullable
  maxPrebuildTemplateVersions: int # format: int32
  repoId: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/prebuilds/templates/updatemaxversions")
  let body = {branchName: $branchName, devContainerPath: $devContainerPath, maxPrebuildTemplateVersions: $maxPrebuildTemplateVersions, repoId: $repoId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /api/v2/prebuilds/templates/{templateId}/updatestatus
export def "prebuilds-templates-updatestatus post" [
  templateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --isSuccess: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/prebuilds/templates/($templateId)/updatestatus")
  let body = {isSuccess: $isSuccess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --macAddress: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "macAddress" $macAddress "scalar")] | flatten | str join "&"
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
export def "tunnelauth post" [
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
