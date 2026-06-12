# Auto-generated client for PingOne Platform API v2026.01.07-beta
# Source: https://raw.githubusercontent.com/pingidentity/pingone-openapi-specifications/main/specification/3.1/api/combined/openapi.yaml
# Auth: --token flag or $env.PINGONE_PLATFORM_API_TOKEN

const BASE_URL = "https://api.pingone.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PINGONE_PLATFORM_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.pingone.com/v1" "https://api.pingone.eu/v1" "https://api.pingone.asia/v1" "https://api.pingone.com.au/v1" "https://api.pingone.ca/v1" "https://api.pingone.sg/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/hal+json" "application/json"] }
def region-completer [] { ["AP" "AU" "CA" "EU" "NA" "SG"] }
def type-completer [] { ["PRODUCTION" "SANDBOX"] }
def subtype-completer [] { ["DEV" "QA" "STAGING" "TESTING" "UAT"] }
def status-completer [] { ["ACTIVE" "DELETE_PENDING"] }
def status-completer-1 [] { ["disabled" "enabled"] }
def context-completer [] { ["company" "flow" "flowInstance" "user"] }
def dataType-completer [] { ["boolean" "number" "object" "secret" "string"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "environments list" } } | get name | first)
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

# GET /environments
#
# operationId: getEnvironments
export def "environments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --expand: string
  --filter: string
  --order: string
  --limit: int # format: int32, default: 1000
  --cursor: string
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_embedded: record<environments: list<record>>, _links: record<next: record<href: string, name: string, profile: string, title: string, type: string>, prev: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>>, count: int, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/environments" $qp)
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /environments
#
# operationId: createEnvironment
# --license shape: {id: string, package?: string}
# --billOfMaterials shape: {products: list, solutionType?: "CIAM_TRIAL"|"CUSTOMER"|"WF_TRIAL"|"WORKFORCE"}
export def "environments createEnvironment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  name: string
  region: string@region-completer
  type: string@type-completer
  license: record # shape: {id: string, package?: string}
  --billOfMaterials: record # shape: {products: list, solutionType?: "CIAM_TRIAL"|"CUSTOMER"|"WF_TRIAL"|"WORKFORCE"}
  --description: string
  --icon: string
  --subtype: string@subtype-completer
]: any -> record<name: string, region: string, type: string, createdAt: string, updatedAt: string, id: string, organization: record<id: string>, _embedded: record, _links: record<self: record<href: string, name: string, profile: string, title: string, type: string>>, billOfMaterials: record<products: list<record>, solutionType: string>, description: string, environmentCapabilities: record<_embedded: record, _links: record<self: record>, canAddResources: bool, canAssignCustomRolesEverywhere: bool, canAssignUsersRoles: bool, canContactSupport: bool, canCreateConnections: bool, canCreateCustomDomain: bool, canPromoteToProd: bool, canSendMfaNotificationsOutsideWhitelist: bool, canSendPasswordManagementNotifications: bool, canSendVerificationFlowNotifications: bool, canUseAadhaar: bool, canUseAamva: bool, canUseAccountOwnership: bool, canUseAccountProtection: bool, canUseAccountTakeoverDetection: bool, canUseApiAccessManagement: bool, canUseApplicationPermissions: bool, canUseBotMaliciousDeviceDetection: bool, canUseCredentialSharingDetection: bool, canUseCredentials: bool, canUseCredentialsPushNotifications: bool, canUseCustomSchema: bool, canUseDaVinciAdminPortal: bool, canUseDataAnalyticsSupport: bool, canUseDataBasedVerifications: bool, canUseDataVerificationGroup1: bool, canUseDataVerificationGroup2: bool, canUseDataVerificationGroup3: bool, canUseDataVerificationGroup4: bool, canUseDataVerificationGroup5: bool, canUseDeviceReputationScoring: bool, canUseDigitalVerifications: bool, canUseDocumentMatch: bool, canUseDynamicAuthorization: bool, canUseEditNotificationTemplate: bool, canUseEmailOtp: bool, canUseFaceMatch: bool, canUseFraudDataEnrichment: bool, canUseGlobalWatchlist: bool, canUseIdentities: bool, canUseIdentityProviders: bool, canUseInboundProvisioning: bool, canUseIntelligence: bool, canUseIntelligenceAdvancedPredictors: bool, canUseIntelligenceAnonymousNetworkDetection: bool, canUseIntelligenceDataConsent: bool, canUseIntelligenceEditPolicyScores: bool, canUseIntelligenceGeoVelocity: bool, canUseIntelligenceLastTransactionOlderThan: bool, canUseIntelligenceLimitedCompositePredictor: bool, canUseIntelligenceNewDevicePredictor: bool, canUseIntelligenceProtect: bool, canUseIntelligenceReputation: bool, canUseIntelligenceRisk: bool, canUseIntelligenceTrustDevicePredictor: bool, canUseKerberosGateway: bool, canUseLdapGateway: bool, canUseLiveAgent: bool, canUseManualIDStepUpInspection: bool, canUseManualIdInspection: bool, canUseMfa: bool, canUseMfaCiam: bool, canUseMfaFido2Devices: bool, canUseMfaPushNotifications: bool, canUseMfaVoiceOtp: bool, canUseMfaWf: bool, canUseMyAccount: bool, canUseNewAccountFraudDetection: bool, canUseOATHToken: bool, canUseOrchestration: bool, canUsePasswordManagement: bool, canUsePasswordOnlyAuthentication: bool, canUsePasswordPolicy: bool, canUsePingIDApp: bool, canUsePingIdDesktop: bool, canUsePingIdDesktopGen2: bool, canUsePingSmsAccount: bool, canUsePlatform: bool, canUseProtectTransactions: bool, canUseProvisioning: bool, canUseRadiusGateway: bool, canUseScheduledFlows: bool, canUseSmsOtp: bool, canUseTotp: bool, canUseUniversalDeviceId: bool, canUseVerificationFlow: bool, canUseVerify: bool, canUseVerifyPushNotifications: bool, canUseVerifyVoice: bool, canUseWhatsAppOtp: bool, canUseWinLogin: bool, canUseYubikey: bool, canUsersUpdateSelf: bool, environmentId: string, getcanUseUniversalCapture: bool, licenseQuantities: record<numberOfAadhaar: int, numberOfAccountOwnership: int, numberOfDataVerificationGroup1: int, numberOfDataVerificationGroup2: int, numberOfDataVerificationGroup3: int, numberOfDataVerificationGroup4: int, numberOfDataVerificationGroup5: int, numberOfDataVerifications: int, numberOfDeviceReputationScoring: int, numberOfGlobalWatchlist: int, numberOfLiveAgent: int, rlgAnalyticsRpm: record, rlgAppRegRpm: record, rlgAuditRps: record, rlgAuthnRps: record, rlgAuthnStartRps: record, rlgAuthzBulkRps: record, rlgAuthzRps: record, rlgCatchAllRps: record, rlgConfigRpm: record, rlgCredRpm: record, rlgDirAccessRps: record, rlgDirBulkRps: record, rlgDirFixedRps: record, rlgDirWriteRps: record, rlgDvFlowCallbackRps: record, rlgDvFlowExecRps: record, rlgDvFlowStartRps: record, rlgMfaFixedRps: record, rlgMfaPollingRps: record, rlgMfaRps: record, rlgPrivilegeRps: record, rlgRiskEvalsRps: record, rlgTokenCheckRps: record, rlgVerifyRpm: record>>, hardDeleteAllowedAt: string, icon: string, license: record<id: string, package: string>, pingoneAccountId: string, softDeletedAt: string, status: string, subtype: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/environments")
  let body = {name: $name, region: $region, type: $type, license: $license, billOfMaterials: $billOfMaterials, description: $description, icon: $icon, subtype: $subtype} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /environments/{environmentID}
#
# operationId: getEnvironmentById
export def "environments get" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --expand: string
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<name: string, region: string, type: string, createdAt: string, updatedAt: string, id: string, organization: record<id: string>, _embedded: record, _links: record<self: record<href: string, name: string, profile: string, title: string, type: string>>, billOfMaterials: record<products: list<record>, solutionType: string>, description: string, environmentCapabilities: record<_embedded: record, _links: record<self: record>, canAddResources: bool, canAssignCustomRolesEverywhere: bool, canAssignUsersRoles: bool, canContactSupport: bool, canCreateConnections: bool, canCreateCustomDomain: bool, canPromoteToProd: bool, canSendMfaNotificationsOutsideWhitelist: bool, canSendPasswordManagementNotifications: bool, canSendVerificationFlowNotifications: bool, canUseAadhaar: bool, canUseAamva: bool, canUseAccountOwnership: bool, canUseAccountProtection: bool, canUseAccountTakeoverDetection: bool, canUseApiAccessManagement: bool, canUseApplicationPermissions: bool, canUseBotMaliciousDeviceDetection: bool, canUseCredentialSharingDetection: bool, canUseCredentials: bool, canUseCredentialsPushNotifications: bool, canUseCustomSchema: bool, canUseDaVinciAdminPortal: bool, canUseDataAnalyticsSupport: bool, canUseDataBasedVerifications: bool, canUseDataVerificationGroup1: bool, canUseDataVerificationGroup2: bool, canUseDataVerificationGroup3: bool, canUseDataVerificationGroup4: bool, canUseDataVerificationGroup5: bool, canUseDeviceReputationScoring: bool, canUseDigitalVerifications: bool, canUseDocumentMatch: bool, canUseDynamicAuthorization: bool, canUseEditNotificationTemplate: bool, canUseEmailOtp: bool, canUseFaceMatch: bool, canUseFraudDataEnrichment: bool, canUseGlobalWatchlist: bool, canUseIdentities: bool, canUseIdentityProviders: bool, canUseInboundProvisioning: bool, canUseIntelligence: bool, canUseIntelligenceAdvancedPredictors: bool, canUseIntelligenceAnonymousNetworkDetection: bool, canUseIntelligenceDataConsent: bool, canUseIntelligenceEditPolicyScores: bool, canUseIntelligenceGeoVelocity: bool, canUseIntelligenceLastTransactionOlderThan: bool, canUseIntelligenceLimitedCompositePredictor: bool, canUseIntelligenceNewDevicePredictor: bool, canUseIntelligenceProtect: bool, canUseIntelligenceReputation: bool, canUseIntelligenceRisk: bool, canUseIntelligenceTrustDevicePredictor: bool, canUseKerberosGateway: bool, canUseLdapGateway: bool, canUseLiveAgent: bool, canUseManualIDStepUpInspection: bool, canUseManualIdInspection: bool, canUseMfa: bool, canUseMfaCiam: bool, canUseMfaFido2Devices: bool, canUseMfaPushNotifications: bool, canUseMfaVoiceOtp: bool, canUseMfaWf: bool, canUseMyAccount: bool, canUseNewAccountFraudDetection: bool, canUseOATHToken: bool, canUseOrchestration: bool, canUsePasswordManagement: bool, canUsePasswordOnlyAuthentication: bool, canUsePasswordPolicy: bool, canUsePingIDApp: bool, canUsePingIdDesktop: bool, canUsePingIdDesktopGen2: bool, canUsePingSmsAccount: bool, canUsePlatform: bool, canUseProtectTransactions: bool, canUseProvisioning: bool, canUseRadiusGateway: bool, canUseScheduledFlows: bool, canUseSmsOtp: bool, canUseTotp: bool, canUseUniversalDeviceId: bool, canUseVerificationFlow: bool, canUseVerify: bool, canUseVerifyPushNotifications: bool, canUseVerifyVoice: bool, canUseWhatsAppOtp: bool, canUseWinLogin: bool, canUseYubikey: bool, canUsersUpdateSelf: bool, environmentId: string, getcanUseUniversalCapture: bool, licenseQuantities: record<numberOfAadhaar: int, numberOfAccountOwnership: int, numberOfDataVerificationGroup1: int, numberOfDataVerificationGroup2: int, numberOfDataVerificationGroup3: int, numberOfDataVerificationGroup4: int, numberOfDataVerificationGroup5: int, numberOfDataVerifications: int, numberOfDeviceReputationScoring: int, numberOfGlobalWatchlist: int, numberOfLiveAgent: int, rlgAnalyticsRpm: record, rlgAppRegRpm: record, rlgAuditRps: record, rlgAuthnRps: record, rlgAuthnStartRps: record, rlgAuthzBulkRps: record, rlgAuthzRps: record, rlgCatchAllRps: record, rlgConfigRpm: record, rlgCredRpm: record, rlgDirAccessRps: record, rlgDirBulkRps: record, rlgDirFixedRps: record, rlgDirWriteRps: record, rlgDvFlowCallbackRps: record, rlgDvFlowExecRps: record, rlgDvFlowStartRps: record, rlgMfaFixedRps: record, rlgMfaPollingRps: record, rlgMfaRps: record, rlgPrivilegeRps: record, rlgRiskEvalsRps: record, rlgTokenCheckRps: record, rlgVerifyRpm: record>>, hardDeleteAllowedAt: string, icon: string, license: record<id: string, package: string>, pingoneAccountId: string, softDeletedAt: string, status: string, subtype: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/environments/($environmentID)" $qp)
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /environments/{environmentID}
#
# operationId: replaceEnvironmentById
# --billOfMaterials shape: {products: list}
# --license shape: {id: string, package?: string}
export def "environments replaceEnvironmentById" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  name: string
  region: string@region-completer
  type: string@type-completer
  --billOfMaterials: record # shape: {products: list}
  --description: string
  --icon: string
  --license: record # shape: {id: string, package?: string}
  --status: string@status-completer
  --subtype: string@subtype-completer
]: any -> record<name: string, region: string, type: string, createdAt: string, updatedAt: string, id: string, organization: record<id: string>, _embedded: record, _links: record<self: record<href: string, name: string, profile: string, title: string, type: string>>, billOfMaterials: record<products: list<record>, solutionType: string>, description: string, environmentCapabilities: record<_embedded: record, _links: record<self: record>, canAddResources: bool, canAssignCustomRolesEverywhere: bool, canAssignUsersRoles: bool, canContactSupport: bool, canCreateConnections: bool, canCreateCustomDomain: bool, canPromoteToProd: bool, canSendMfaNotificationsOutsideWhitelist: bool, canSendPasswordManagementNotifications: bool, canSendVerificationFlowNotifications: bool, canUseAadhaar: bool, canUseAamva: bool, canUseAccountOwnership: bool, canUseAccountProtection: bool, canUseAccountTakeoverDetection: bool, canUseApiAccessManagement: bool, canUseApplicationPermissions: bool, canUseBotMaliciousDeviceDetection: bool, canUseCredentialSharingDetection: bool, canUseCredentials: bool, canUseCredentialsPushNotifications: bool, canUseCustomSchema: bool, canUseDaVinciAdminPortal: bool, canUseDataAnalyticsSupport: bool, canUseDataBasedVerifications: bool, canUseDataVerificationGroup1: bool, canUseDataVerificationGroup2: bool, canUseDataVerificationGroup3: bool, canUseDataVerificationGroup4: bool, canUseDataVerificationGroup5: bool, canUseDeviceReputationScoring: bool, canUseDigitalVerifications: bool, canUseDocumentMatch: bool, canUseDynamicAuthorization: bool, canUseEditNotificationTemplate: bool, canUseEmailOtp: bool, canUseFaceMatch: bool, canUseFraudDataEnrichment: bool, canUseGlobalWatchlist: bool, canUseIdentities: bool, canUseIdentityProviders: bool, canUseInboundProvisioning: bool, canUseIntelligence: bool, canUseIntelligenceAdvancedPredictors: bool, canUseIntelligenceAnonymousNetworkDetection: bool, canUseIntelligenceDataConsent: bool, canUseIntelligenceEditPolicyScores: bool, canUseIntelligenceGeoVelocity: bool, canUseIntelligenceLastTransactionOlderThan: bool, canUseIntelligenceLimitedCompositePredictor: bool, canUseIntelligenceNewDevicePredictor: bool, canUseIntelligenceProtect: bool, canUseIntelligenceReputation: bool, canUseIntelligenceRisk: bool, canUseIntelligenceTrustDevicePredictor: bool, canUseKerberosGateway: bool, canUseLdapGateway: bool, canUseLiveAgent: bool, canUseManualIDStepUpInspection: bool, canUseManualIdInspection: bool, canUseMfa: bool, canUseMfaCiam: bool, canUseMfaFido2Devices: bool, canUseMfaPushNotifications: bool, canUseMfaVoiceOtp: bool, canUseMfaWf: bool, canUseMyAccount: bool, canUseNewAccountFraudDetection: bool, canUseOATHToken: bool, canUseOrchestration: bool, canUsePasswordManagement: bool, canUsePasswordOnlyAuthentication: bool, canUsePasswordPolicy: bool, canUsePingIDApp: bool, canUsePingIdDesktop: bool, canUsePingIdDesktopGen2: bool, canUsePingSmsAccount: bool, canUsePlatform: bool, canUseProtectTransactions: bool, canUseProvisioning: bool, canUseRadiusGateway: bool, canUseScheduledFlows: bool, canUseSmsOtp: bool, canUseTotp: bool, canUseUniversalDeviceId: bool, canUseVerificationFlow: bool, canUseVerify: bool, canUseVerifyPushNotifications: bool, canUseVerifyVoice: bool, canUseWhatsAppOtp: bool, canUseWinLogin: bool, canUseYubikey: bool, canUsersUpdateSelf: bool, environmentId: string, getcanUseUniversalCapture: bool, licenseQuantities: record<numberOfAadhaar: int, numberOfAccountOwnership: int, numberOfDataVerificationGroup1: int, numberOfDataVerificationGroup2: int, numberOfDataVerificationGroup3: int, numberOfDataVerificationGroup4: int, numberOfDataVerificationGroup5: int, numberOfDataVerifications: int, numberOfDeviceReputationScoring: int, numberOfGlobalWatchlist: int, numberOfLiveAgent: int, rlgAnalyticsRpm: record, rlgAppRegRpm: record, rlgAuditRps: record, rlgAuthnRps: record, rlgAuthnStartRps: record, rlgAuthzBulkRps: record, rlgAuthzRps: record, rlgCatchAllRps: record, rlgConfigRpm: record, rlgCredRpm: record, rlgDirAccessRps: record, rlgDirBulkRps: record, rlgDirFixedRps: record, rlgDirWriteRps: record, rlgDvFlowCallbackRps: record, rlgDvFlowExecRps: record, rlgDvFlowStartRps: record, rlgMfaFixedRps: record, rlgMfaPollingRps: record, rlgMfaRps: record, rlgPrivilegeRps: record, rlgRiskEvalsRps: record, rlgTokenCheckRps: record, rlgVerifyRpm: record>>, hardDeleteAllowedAt: string, icon: string, license: record<id: string, package: string>, pingoneAccountId: string, softDeletedAt: string, status: string, subtype: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)")
  let body = {name: $name, region: $region, type: $type, billOfMaterials: $billOfMaterials, description: $description, icon: $icon, license: $license, status: $status, subtype: $subtype} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /environments/{environmentID}
#
# operationId: deleteEnvironmentById
export def "environments delete" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/billOfMaterials
#
# operationId: getBillOfMaterialsByEnvironmentId
export def "environments-bill-of-materials get" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_embedded: record, _links: record, createdAt: string, products: table<type: string, bookmarks: list, console: record, deployment: record, description: string, id: string, softwareLicense: record, tags: list>, solutionType: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/billOfMaterials")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /environments/{environmentID}/billOfMaterials
#
# operationId: replaceBillOfMaterialsByEnvironmentId
# --products item shape: {type: "IDENTITY_CLOUD"|"PING_ACCESS"|"PING_AUTHORIZE"|"PING_CENTRAL"|"PING_DATA_GOVERNANCE"|"PING_DATA_SYNC"|"PING_DIRECTORY"|"PING_FEDERATE"|"PING_ID"|"PING_ID_SDK"|"PING_INTELLIGENCE"|"PING_ONE_AUTHORIZE"|"PING_ONE_BASE"|"PING_ONE_CREDENTIALS"|"PING_ONE_DAVINCI"|"PING_ONE_FOR_ENTERPRISE"|"PING_ONE_FOR_SAAS"|"PING_ONE_FRAUD"|"PING_ONE_ID"|"PING_ONE_LEGACY"|"PING_ONE_MFA"|"PING_ONE_ORCHESTRATE"|"PING_ONE_PROVISIONING"|"PING_ONE_RISK"|"PING_ONE_VERIFY", bookmarks?: list, console?: record, deployment?: record, description?: string, softwareLicense?: record, tags?: list}
export def "environments-bill-of-materials replaceBillOfMaterialsByEnvironmentId" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  products: list # item shape: {type: "IDENTITY_CLOUD"|"PING_ACCESS"|"PING_AUTHORIZE"|"PING_CENTRAL"|"PING_DATA_GOVERNANCE"|"PING_DATA_SYNC"|"PING_DIRECTORY"|"PING_FEDERATE"|"PING_ID"|"PING_ID_SDK"|"PING_INTELLIGENCE"|"PING_ONE_AUTHORIZE"|"PING_ONE_BASE"|"PING_ONE_CREDENTIALS"|"PING_ONE_DAVINCI"|"PING_ONE_FOR_ENTERPRISE"|"PING_ONE_FOR_SAAS"|"PING_ONE_FRAUD"|"PING_ONE_ID"|"PING_ONE_LEGACY"|"PING_ONE_MFA"|"PING_ONE_ORCHESTRATE"|"PING_ONE_PROVISIONING"|"PING_ONE_RISK"|"PING_ONE_VERIFY", bookmarks?: list, console?: record, deployment?: record, description?: string, softwareLicense?: record, tags?: list}
]: any -> record<_embedded: record, _links: record, createdAt: string, products: table<type: string, bookmarks: list, console: record, deployment: record, description: string, id: string, softwareLicense: record, tags: list>, solutionType: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/billOfMaterials")
  let body = {products: $products} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /environments/{environmentID}/connectorInstances
#
# operationId: getConnectorInstances
export def "environments-connector-instances list" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_embedded: record<connectorInstances: list<record>>, _links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/connectorInstances")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /environments/{environmentID}/connectorInstances
#
# operationId: createConnectorInstance
# --connector shape: {id: string}
export def "environments-connector-instances createConnectorInstance" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  name: string
  connector: record # shape: {id: string}
  --properties: record
]: any -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, connectorInstance_clone: record<href: string, name: string, profile: string, title: string, type: string>, applications: record<href: string, name: string, profile: string, title: string, type: string>, deviceAuthenticationPolicies: record<href: string, name: string, profile: string, title: string, type: string>, gateways: record<href: string, name: string, profile: string, title: string, type: string>, notificationsPolicies: record<href: string, name: string, profile: string, title: string, type: string>>, connector: record<id: string>, environment: record<id: string>, id: string, name: string, createdAt: string, properties: record, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/connectorInstances")
  let body = {name: $name, connector: $connector, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /environments/{environmentID}/connectorInstances/{connectorInstanceID}
#
# operationId: getConnectorInstanceById
export def "environments-connector-instances get" [
  environmentID: string
  connectorInstanceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, connectorInstance_clone: record<href: string, name: string, profile: string, title: string, type: string>, applications: record<href: string, name: string, profile: string, title: string, type: string>, deviceAuthenticationPolicies: record<href: string, name: string, profile: string, title: string, type: string>, gateways: record<href: string, name: string, profile: string, title: string, type: string>, notificationsPolicies: record<href: string, name: string, profile: string, title: string, type: string>>, connector: record<id: string>, environment: record<id: string>, id: string, name: string, createdAt: string, properties: record, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/connectorInstances/($connectorInstanceID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /environments/{environmentID}/connectorInstances/{connectorInstanceID}
#
# operationId: createConnectorInstanceById
export def "environments-connector-instances createConnectorInstanceById" [
  environmentID: string
  connectorInstanceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  --body: record
]: any -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, connectorInstance_clone: record<href: string, name: string, profile: string, title: string, type: string>, applications: record<href: string, name: string, profile: string, title: string, type: string>, deviceAuthenticationPolicies: record<href: string, name: string, profile: string, title: string, type: string>, gateways: record<href: string, name: string, profile: string, title: string, type: string>, notificationsPolicies: record<href: string, name: string, profile: string, title: string, type: string>>, connector: record<id: string>, environment: record<id: string>, id: string, name: string, createdAt: string, properties: record, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/connectorInstances/($connectorInstanceID)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.pingidentity.connectorInstance.clone+json" $body
}

# PUT /environments/{environmentID}/connectorInstances/{connectorInstanceID}
#
# operationId: replaceConnectorInstanceById
# --connector shape: {id: string}
export def "environments-connector-instances replaceConnectorInstanceById" [
  environmentID: string
  connectorInstanceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  name: string
  connector: record # shape: {id: string}
  --properties: record
]: any -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, connectorInstance_clone: record<href: string, name: string, profile: string, title: string, type: string>, applications: record<href: string, name: string, profile: string, title: string, type: string>, deviceAuthenticationPolicies: record<href: string, name: string, profile: string, title: string, type: string>, gateways: record<href: string, name: string, profile: string, title: string, type: string>, notificationsPolicies: record<href: string, name: string, profile: string, title: string, type: string>>, connector: record<id: string>, environment: record<id: string>, id: string, name: string, createdAt: string, properties: record, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/connectorInstances/($connectorInstanceID)")
  let body = {name: $name, connector: $connector, properties: $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /environments/{environmentID}/connectorInstances/{connectorInstanceID}
#
# operationId: deleteConnectorInstanceById
export def "environments-connector-instances delete" [
  environmentID: string
  connectorInstanceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/connectorInstances/($connectorInstanceID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/connectors
#
# operationId: getConnectors
export def "environments-connectors list" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_embedded: record<connectors: list<record>>, _links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/connectors")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/connectors/{connectorID}
#
# operationId: getConnectorById
export def "environments-connectors get" [
  environmentID: string
  connectorID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>>, createdAt: string, environment: record<id: string>, id: string, metadata: record<colors: record<canvas: string, canvasText: string, dark: string>, logos: record<canvas: record>, type: string, vendor: string>, name: string, version: string, description: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/connectors/($connectorID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/connectors/{connectorID}/details
#
# operationId: getDetailsByConnectorId
export def "environments-connectors-details get" [
  environmentID: string
  connectorID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<environment: record<id: string>, _links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>>, accountConfigView: record<items: list<record>, componentViewSize: string>, capabilities: record, credentialsView: record<items: list<record>>, flowSections: table<name: string, value: string>, properties: record, sections: table<name: string, value: string, default: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/connectors/($connectorID)/details")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/davinciApplications
#
# operationId: getDavinciApplications
export def "environments-davinci-applications list" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>>, _embedded: record<davinciApplications: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /environments/{environmentID}/davinciApplications
#
# operationId: createDavinciApplication
export def "environments-davinci-applications createDavinciApplication" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  name: string
]: any -> record<_links: record<self: record<href: string, name: string, profile: string, title: string, type: string>, environment: record<href: string, name: string, profile: string, title: string, type: string>, flowPolicies: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication_rotateKey: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication_rotateSecret: record<href: string, name: string, profile: string, title: string, type: string>>, apiKey: record<enabled: bool, value: string>, environment: record<id: string>, id: string, name: string, oauth: record<clientSecret: string, enforceSignedRequestOpenid: bool, grantTypes: list<string>, logoutUris: list<string>, redirectUris: list<string>, scopes: list<string>, spJwksOpenid: string, spjwksUrl: string>, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /environments/{environmentID}/davinciApplications/{davinciApplicationID}
#
# operationId: getDavinciApplicationById
export def "environments-davinci-applications get" [
  environmentID: string
  davinciApplicationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_links: record<self: record<href: string, name: string, profile: string, title: string, type: string>, environment: record<href: string, name: string, profile: string, title: string, type: string>, flowPolicies: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication_rotateKey: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication_rotateSecret: record<href: string, name: string, profile: string, title: string, type: string>>, apiKey: record<enabled: bool, value: string>, environment: record<id: string>, id: string, name: string, oauth: record<clientSecret: string, enforceSignedRequestOpenid: bool, grantTypes: list<string>, logoutUris: list<string>, redirectUris: list<string>, scopes: list<string>, spJwksOpenid: string, spjwksUrl: string>, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications/($davinciApplicationID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /environments/{environmentID}/davinciApplications/{davinciApplicationID}
#
# operationId: replaceDavinciApplicationById
# --apiKey shape: {enabled?: bool}
# --oauth shape: {enforceSignedRequestOpenid?: bool, grantTypes?: list, logoutUris?: list, redirectUris?: list, scopes?: list, spJwksOpenid?: string, spjwksUrl?: string}
export def "environments-davinci-applications replaceDavinciApplicationById" [
  environmentID: string
  davinciApplicationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  name: string
  --apiKey: record # shape: {enabled?: bool}
  --oauth: record # shape: {enforceSignedRequestOpenid?: bool, grantTypes?: list, logoutUris?: list, redirectUris?: list, scopes?: list, spJwksOpenid?: string, spjwksUrl?: string}
]: any -> record<_links: record<self: record<href: string, name: string, profile: string, title: string, type: string>, environment: record<href: string, name: string, profile: string, title: string, type: string>, flowPolicies: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication_rotateKey: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication_rotateSecret: record<href: string, name: string, profile: string, title: string, type: string>>, apiKey: record<enabled: bool, value: string>, environment: record<id: string>, id: string, name: string, oauth: record<clientSecret: string, enforceSignedRequestOpenid: bool, grantTypes: list<string>, logoutUris: list<string>, redirectUris: list<string>, scopes: list<string>, spJwksOpenid: string, spjwksUrl: string>, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications/($davinciApplicationID)")
  let body = {name: $name, apiKey: $apiKey, oauth: $oauth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /environments/{environmentID}/davinciApplications/{davinciApplicationID}
#
# operationId: deleteDavinciApplicationById
export def "environments-davinci-applications delete" [
  environmentID: string
  davinciApplicationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications/($davinciApplicationID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/davinciApplications/{davinciApplicationID}/flowPolicies
#
# operationId: getFlowPoliciesByDavinciApplicationId
export def "environments-davinci-applications-flow-policies list" [
  environmentID: string
  davinciApplicationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_links: record<self: record<href: string, name: string, profile: string, title: string, type: string>, environment: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication: record<href: string, name: string, profile: string, title: string, type: string>>, _embedded: record<flowPolicies: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications/($davinciApplicationID)/flowPolicies")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /environments/{environmentID}/davinciApplications/{davinciApplicationID}/flowPolicies
#
# operationId: createFlowPolicyByDavinciApplicationId
# --flowDistributions item shape: {id: string, version: float, ip?: list, successNodes?: list, weight?: float}
# --trigger shape: {configuration?: record, type?: "AUTHENTICATION"}
export def "environments-davinci-applications-flow-policies createFlowPolicyByDavinciApplicationId" [
  environmentID: string
  davinciApplicationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  flowDistributions: list # item shape: {id: string, version: float, ip?: list, successNodes?: list, weight?: float}
  --name: string # default: New Policy
  --status: string@status-completer-1 # default: enabled
  --trigger: record # shape: {configuration?: record, type?: "AUTHENTICATION"}
]: any -> record<_links: record<self: record<href: string, name: string, profile: string, title: string, type: string>, environment: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication: record<href: string, name: string, profile: string, title: string, type: string>, flow__index_: record<href: string, name: string, profile: string, title: string, type: string>, version__flowId___index_: record<href: string, name: string, profile: string, title: string, type: string>>, environment: record<id: string>, flowDistributions: table<id: string, version: float, ip: list, successNodes: list, weight: float>, id: string, name: string, status: string, application: record<id: string>, createdAt: string, trigger: record<configuration: record<mfa: record, pwd: record>, type: string>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications/($davinciApplicationID)/flowPolicies")
  let body = {flowDistributions: $flowDistributions, name: $name, status: $status, trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /environments/{environmentID}/davinciApplications/{davinciApplicationID}/flowPolicies/{flowPolicyID}
#
# operationId: getFlowPolicyByIdUsingDavinciApplicationId
export def "environments-davinci-applications-flow-policies get" [
  environmentID: string
  davinciApplicationID: string
  flowPolicyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_links: record<self: record<href: string, name: string, profile: string, title: string, type: string>, environment: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication: record<href: string, name: string, profile: string, title: string, type: string>, flow__index_: record<href: string, name: string, profile: string, title: string, type: string>, version__flowId___index_: record<href: string, name: string, profile: string, title: string, type: string>>, environment: record<id: string>, flowDistributions: table<id: string, version: float, ip: list, successNodes: list, weight: float>, id: string, name: string, status: string, application: record<id: string>, createdAt: string, trigger: record<configuration: record<mfa: record, pwd: record>, type: string>, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications/($davinciApplicationID)/flowPolicies/($flowPolicyID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /environments/{environmentID}/davinciApplications/{davinciApplicationID}/flowPolicies/{flowPolicyID}
#
# operationId: replaceFlowPolicyByIdUsingDavinciApplicationId
# --flowDistributions item shape: {id: string, version: float, ip?: list, successNodes?: list, weight?: float}
# --trigger shape: {configuration?: record, type?: "AUTHENTICATION"}
export def "environments-davinci-applications-flow-policies replaceFlowPolicyByIdUsingDavinciApplicationId" [
  environmentID: string
  davinciApplicationID: string
  flowPolicyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  name: string # default: New Policy
  --flowDistributions: list # item shape: {id: string, version: float, ip?: list, successNodes?: list, weight?: float}
  --status: string@status-completer-1 # default: enabled
  --trigger: record # shape: {configuration?: record, type?: "AUTHENTICATION"}
]: any -> record<_links: record<self: record<href: string, name: string, profile: string, title: string, type: string>, environment: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication: record<href: string, name: string, profile: string, title: string, type: string>, flow__index_: record<href: string, name: string, profile: string, title: string, type: string>, version__flowId___index_: record<href: string, name: string, profile: string, title: string, type: string>>, environment: record<id: string>, flowDistributions: table<id: string, version: float, ip: list, successNodes: list, weight: float>, id: string, name: string, status: string, application: record<id: string>, createdAt: string, trigger: record<configuration: record<mfa: record, pwd: record>, type: string>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications/($davinciApplicationID)/flowPolicies/($flowPolicyID)")
  let body = {name: $name, flowDistributions: $flowDistributions, status: $status, trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /environments/{environmentID}/davinciApplications/{davinciApplicationID}/flowPolicies/{flowPolicyID}
#
# operationId: deleteFlowPolicyByIdUsingDavinciApplicationId
export def "environments-davinci-applications-flow-policies delete" [
  environmentID: string
  davinciApplicationID: string
  flowPolicyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications/($davinciApplicationID)/flowPolicies/($flowPolicyID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/davinciApplications/{davinciApplicationID}/flowPolicies/{flowPolicyID}/events
#
# operationId: getEventsByDavinciApplicationIdAndFlowPolicyId
export def "environments-davinci-applications-flow-policies-events get" [
  environmentID: string
  davinciApplicationID: string
  flowPolicyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_links: record<self: record<href: string, name: string, profile: string, title: string, type: string>, environment: record<href: string, name: string, profile: string, title: string, type: string>>, _embedded: record<events: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications/($davinciApplicationID)/flowPolicies/($flowPolicyID)/events")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /environments/{environmentID}/davinciApplications/{davinciApplicationID}/key
#
# operationId: rotateKeyByDavinciApplicationId
export def "environments-davinci-applications-key rotateKeyByDavinciApplicationId" [
  environmentID: string
  davinciApplicationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  --body: record
]: any -> record<_links: record<self: record<href: string, name: string, profile: string, title: string, type: string>, environment: record<href: string, name: string, profile: string, title: string, type: string>, flowPolicies: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication_rotateKey: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication_rotateSecret: record<href: string, name: string, profile: string, title: string, type: string>>, apiKey: record<enabled: bool, value: string>, environment: record<id: string>, id: string, name: string, oauth: record<clientSecret: string, enforceSignedRequestOpenid: bool, grantTypes: list<string>, logoutUris: list<string>, redirectUris: list<string>, scopes: list<string>, spJwksOpenid: string, spjwksUrl: string>, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications/($davinciApplicationID)/key")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.pingidentity.davinciApplication.rotateKey+json" $body
}

# POST /environments/{environmentID}/davinciApplications/{davinciApplicationID}/secret
#
# operationId: rotateSecretByDavinciApplicationId
export def "environments-davinci-applications-secret rotateSecretByDavinciApplicationId" [
  environmentID: string
  davinciApplicationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  --body: record
]: any -> record<_links: record<self: record<href: string, name: string, profile: string, title: string, type: string>, environment: record<href: string, name: string, profile: string, title: string, type: string>, flowPolicies: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication_rotateKey: record<href: string, name: string, profile: string, title: string, type: string>, davinciApplication_rotateSecret: record<href: string, name: string, profile: string, title: string, type: string>>, apiKey: record<enabled: bool, value: string>, environment: record<id: string>, id: string, name: string, oauth: record<clientSecret: string, enforceSignedRequestOpenid: bool, grantTypes: list<string>, logoutUris: list<string>, redirectUris: list<string>, scopes: list<string>, spJwksOpenid: string, spjwksUrl: string>, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/davinciApplications/($davinciApplicationID)/secret")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.pingidentity.davinciApplication.rotateSecret+json" $body
}

# GET /environments/{environmentID}/flowPolicies/{flowPolicyID}
#
# operationId: getFlowPolicyById
export def "environments-flow-policies get" [
  environmentID: string
  flowPolicyID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<id: string, _embedded: record, _links: record<self: record<href: string, name: string, profile: string, title: string, type: string>>, application: record<id: string, name: string>, enabled: bool, environment: record<id: string>, name: string, trigger: record<type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/flowPolicies/($flowPolicyID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/flows
#
# operationId: getFlows
export def "environments-flows list" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_embedded: record<flows: list<record>>, _links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>>, count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/environments/($environmentID)/flows" $qp)
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /environments/{environmentID}/flows
#
# operationId: createFlow
# --graphData shape: {boxSelectionEnabled?: bool, data?: record, elements?: record, maxZoom?: float, minZoom?: float, pan?: record, panningEnabled?: bool, renderer?: record, userPanningEnabled?: bool, userZoomingEnabled?: bool, zoom?: int, zoomingEnabled?: bool}
# --inputSchema item shape: {propertyName: string, preferredDataType: "array"|"boolean"|"number"|"object"|"string", description?: string, isExpanded?: bool, preferredControlType?: "button"|"colorPicker"|"contentEditableTextArea"|"cssArea"|"dropDown"|"dropDownMultiSelect"|"dropDownMultiSelect2"|"dropDownWithCreate"|"functionArgumentList"|"keyValueList"|"label"|"radioSelect"|"textArea"|"textField"|"textFieldArrayView"|"toggleSwitch", required?: bool}
# --outputSchema shape: {output: record}
# --settings shape: {csp?: string, css?: string, cssLinks?: list, customErrorScreenBrandLogoUrl?: string, customErrorShowFooter?: any, customFaviconLink?: string, customLogoURLSelection?: int, customTitle?: string, defaultErrorScreenBrandLogo?: any, flowHttpTimeoutInSeconds?: int, flowTimeoutInSeconds?: int, intermediateLoadingScreenCSS?: any, intermediateLoadingScreenHTML?: any, jsCustomFlowPlayer?: string, jsLinks?: list, logLevel?: int, requireAuthenticationToInitiate?: any, scrubSensitiveInfo?: any, sensitiveInfoFields?: list, useCSP?: any, useCustomCSS?: any, useCustomFlowPlayer?: any, useCustomScript?: any, useIntermediateLoadingScreen?: any, validateOnSave?: any}
# --trigger shape: {type: "AUTHENTICATION"|"SCHEDULE", configuration?: record}
export def "environments-flows createFlow" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  name: string
  --color: string
  --description: string
  --graphData: record # shape: {boxSelectionEnabled?: bool, data?: record, elements?: record, maxZoom?: float, minZoom?: float, pan?: record, panningEnabled?: bool, renderer?: record, userPanningEnabled?: bool, userZoomingEnabled?: bool, zoom?: int, zoomingEnabled?: bool}
  --inputSchema: list # item shape: {propertyName: string, preferredDataType: "array"|"boolean"|"number"|"object"|"string", description?: string, isExpanded?: bool, preferredControlType?: "button"|"colorPicker"|"contentEditableTextArea"|"cssArea"|"dropDown"|"dropDownMultiSelect"|"dropDownMultiSelect2"|"dropDownWithCreate"|"functionArgumentList"|"keyValueList"|"label"|"radioSelect"|"textArea"|"textField"|"textFieldArrayView"|"toggleSwitch", required?: bool}
  --outputSchema: record # shape: {output: record}
  --settings: record # shape: {csp?: string, css?: string, cssLinks?: list, customErrorScreenBrandLogoUrl?: string, customErrorShowFooter?: any, customFaviconLink?: string, customLogoURLSelection?: int, customTitle?: string, defaultErrorScreenBrandLogo?: any, flowHttpTimeoutInSeconds?: int, flowTimeoutInSeconds?: int, intermediateLoadingScreenCSS?: any, intermediateLoadingScreenHTML?: any, jsCustomFlowPlayer?: string, jsLinks?: list, logLevel?: int, requireAuthenticationToInitiate?: any, scrubSensitiveInfo?: any, sensitiveInfoFields?: list, useCSP?: any, useCustomCSS?: any, useCustomFlowPlayer?: any, useCustomScript?: any, useIntermediateLoadingScreen?: any, validateOnSave?: any}
  --trigger: record # shape: {type: "AUTHENTICATION"|"SCHEDULE", configuration?: record}
]: any -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, connectorInstances: record<href: string, name: string, profile: string, title: string, type: string>, connectors: record<href: string, name: string, profile: string, title: string, type: string>, flow_deploy: record<href: string, name: string, profile: string, title: string, type: string>, flow_clone: record<href: string, name: string, profile: string, title: string, type: string>, flow_enabled: record<href: string, name: string, profile: string, title: string, type: string>, version: record<href: string, name: string, profile: string, title: string, type: string>, flow_validate: record<href: string, name: string, profile: string, title: string, type: string>>, environment: record<id: string>, id: string, name: string, color: string, connectors: table<id: string>, createdAt: string, currentVersion: float, deployedAt: string, description: string, dvlinterErrorCount: float, dvlinterWarningCount: float, enabled: bool, graphData: record<boxSelectionEnabled: bool, elements: record<nodes: list, edges: list>, pan: record<x: float, y: float>, panningEnabled: bool, renderer: record<name: string>, userPanningEnabled: bool, userZoomingEnabled: bool, zoom: float, allLinterErrors: list<record>, data: record, maxZoom: float, minZoom: float, zoomingEnabled: bool>, inputSchema: table<preferredControlType: string, preferredDataType: string, propertyName: string, description: string, isExpanded: bool, required: bool>, outputSchema: record<output: record<properties: record, type: string, additionalProperties: bool>>, publishedVersion: float, settings: record<csp: string, css: string, cssLinks: list<string>, customErrorScreenBrandLogoUrl: string, customErrorShowFooter: any, customFaviconLink: string, customLogoURLSelection: int, customTitle: string, defaultErrorScreenBrandLogo: any, flowHttpTimeoutInSeconds: int, flowTimeoutInSeconds: float, intermediateLoadingScreenCSS: any, intermediateLoadingScreenHTML: any, jsCustomFlowPlayer: string, jsLinks: list<record>, logLevel: int, requireAuthenticationToInitiate: any, scrubSensitiveInfo: any, sensitiveInfoFields: list<string>, useCSP: any, useCustomCSS: any, useCustomFlowPlayer: any, useCustomScript: any, useIntermediateLoadingScreen: any, validateOnSave: any>, trigger: record<type: string, configuration: record<mfa: record, pwd: record>>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/flows")
  let body = {name: $name, color: $color, description: $description, graphData: $graphData, inputSchema: $inputSchema, outputSchema: $outputSchema, settings: $settings, trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /environments/{environmentID}/flows/{flowID}
#
# operationId: getFlowById
export def "environments-flows get" [
  environmentID: string
  flowID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attributes: string
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, connectorInstances: record<href: string, name: string, profile: string, title: string, type: string>, connectors: record<href: string, name: string, profile: string, title: string, type: string>, flow_deploy: record<href: string, name: string, profile: string, title: string, type: string>, flow_clone: record<href: string, name: string, profile: string, title: string, type: string>, flow_enabled: record<href: string, name: string, profile: string, title: string, type: string>, version: record<href: string, name: string, profile: string, title: string, type: string>, flow_validate: record<href: string, name: string, profile: string, title: string, type: string>>, environment: record<id: string>, id: string, name: string, color: string, connectors: table<id: string>, createdAt: string, currentVersion: float, deployedAt: string, description: string, dvlinterErrorCount: float, dvlinterWarningCount: float, enabled: bool, graphData: record<boxSelectionEnabled: bool, elements: record<nodes: list, edges: list>, pan: record<x: float, y: float>, panningEnabled: bool, renderer: record<name: string>, userPanningEnabled: bool, userZoomingEnabled: bool, zoom: float, allLinterErrors: list<record>, data: record, maxZoom: float, minZoom: float, zoomingEnabled: bool>, inputSchema: table<preferredControlType: string, preferredDataType: string, propertyName: string, description: string, isExpanded: bool, required: bool>, outputSchema: record<output: record<properties: record, type: string, additionalProperties: bool>>, publishedVersion: float, settings: record<csp: string, css: string, cssLinks: list<string>, customErrorScreenBrandLogoUrl: string, customErrorShowFooter: any, customFaviconLink: string, customLogoURLSelection: int, customTitle: string, defaultErrorScreenBrandLogo: any, flowHttpTimeoutInSeconds: int, flowTimeoutInSeconds: float, intermediateLoadingScreenCSS: any, intermediateLoadingScreenHTML: any, jsCustomFlowPlayer: string, jsLinks: list<record>, logLevel: int, requireAuthenticationToInitiate: any, scrubSensitiveInfo: any, sensitiveInfoFields: list<string>, useCSP: any, useCustomCSS: any, useCustomFlowPlayer: any, useCustomScript: any, useIntermediateLoadingScreen: any, validateOnSave: any>, trigger: record<type: string, configuration: record<mfa: record, pwd: record>>, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributes" $attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/environments/($environmentID)/flows/($flowID)" $qp)
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /environments/{environmentID}/flows/{flowID}
#
# operationId: replaceFlowById
# --graphData shape: {boxSelectionEnabled?: bool, data?: record, elements?: record, maxZoom?: float, minZoom?: float, pan?: record, panningEnabled?: bool, renderer?: record, userPanningEnabled?: bool, userZoomingEnabled?: bool, zoom?: int, zoomingEnabled?: bool}
# --inputSchema item shape: {propertyName: string, preferredDataType: "array"|"boolean"|"number"|"object"|"string", description?: string, isExpanded?: bool, preferredControlType?: "button"|"colorPicker"|"contentEditableTextArea"|"cssArea"|"dropDown"|"dropDownMultiSelect"|"dropDownMultiSelect2"|"dropDownWithCreate"|"functionArgumentList"|"keyValueList"|"label"|"radioSelect"|"textArea"|"textField"|"textFieldArrayView"|"toggleSwitch", required?: bool}
# --outputSchema shape: {output: record}
# --settings shape: {csp?: string, css?: string, cssLinks?: list, customErrorScreenBrandLogoUrl?: string, customErrorShowFooter?: any, customFaviconLink?: string, customLogoURLSelection?: int, customTitle?: string, defaultErrorScreenBrandLogo?: any, flowHttpTimeoutInSeconds?: int, flowTimeoutInSeconds?: int, intermediateLoadingScreenCSS?: any, intermediateLoadingScreenHTML?: any, jsCustomFlowPlayer?: string, jsLinks?: list, logLevel?: int, requireAuthenticationToInitiate?: any, scrubSensitiveInfo?: any, sensitiveInfoFields?: list, useCSP?: any, useCustomCSS?: any, useCustomFlowPlayer?: any, useCustomScript?: any, useIntermediateLoadingScreen?: any, validateOnSave?: any}
# --trigger shape: {type: "AUTHENTICATION"|"SCHEDULE", configuration?: record}
export def "environments-flows replaceFlowById" [
  environmentID: string
  flowID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  name: string
  --color: string
  --description: string
  --graphData: record # shape: {boxSelectionEnabled?: bool, data?: record, elements?: record, maxZoom?: float, minZoom?: float, pan?: record, panningEnabled?: bool, renderer?: record, userPanningEnabled?: bool, userZoomingEnabled?: bool, zoom?: int, zoomingEnabled?: bool}
  --inputSchema: list # item shape: {propertyName: string, preferredDataType: "array"|"boolean"|"number"|"object"|"string", description?: string, isExpanded?: bool, preferredControlType?: "button"|"colorPicker"|"contentEditableTextArea"|"cssArea"|"dropDown"|"dropDownMultiSelect"|"dropDownMultiSelect2"|"dropDownWithCreate"|"functionArgumentList"|"keyValueList"|"label"|"radioSelect"|"textArea"|"textField"|"textFieldArrayView"|"toggleSwitch", required?: bool}
  --outputSchema: record # shape: {output: record}
  --settings: record # shape: {csp?: string, css?: string, cssLinks?: list, customErrorScreenBrandLogoUrl?: string, customErrorShowFooter?: any, customFaviconLink?: string, customLogoURLSelection?: int, customTitle?: string, defaultErrorScreenBrandLogo?: any, flowHttpTimeoutInSeconds?: int, flowTimeoutInSeconds?: int, intermediateLoadingScreenCSS?: any, intermediateLoadingScreenHTML?: any, jsCustomFlowPlayer?: string, jsLinks?: list, logLevel?: int, requireAuthenticationToInitiate?: any, scrubSensitiveInfo?: any, sensitiveInfoFields?: list, useCSP?: any, useCustomCSS?: any, useCustomFlowPlayer?: any, useCustomScript?: any, useIntermediateLoadingScreen?: any, validateOnSave?: any}
  --trigger: record # shape: {type: "AUTHENTICATION"|"SCHEDULE", configuration?: record}
]: any -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, connectorInstances: record<href: string, name: string, profile: string, title: string, type: string>, connectors: record<href: string, name: string, profile: string, title: string, type: string>, flow_deploy: record<href: string, name: string, profile: string, title: string, type: string>, flow_clone: record<href: string, name: string, profile: string, title: string, type: string>, flow_enabled: record<href: string, name: string, profile: string, title: string, type: string>, version: record<href: string, name: string, profile: string, title: string, type: string>, flow_validate: record<href: string, name: string, profile: string, title: string, type: string>>, environment: record<id: string>, id: string, name: string, color: string, connectors: table<id: string>, createdAt: string, currentVersion: float, deployedAt: string, description: string, dvlinterErrorCount: float, dvlinterWarningCount: float, enabled: bool, graphData: record<boxSelectionEnabled: bool, elements: record<nodes: list, edges: list>, pan: record<x: float, y: float>, panningEnabled: bool, renderer: record<name: string>, userPanningEnabled: bool, userZoomingEnabled: bool, zoom: float, allLinterErrors: list<record>, data: record, maxZoom: float, minZoom: float, zoomingEnabled: bool>, inputSchema: table<preferredControlType: string, preferredDataType: string, propertyName: string, description: string, isExpanded: bool, required: bool>, outputSchema: record<output: record<properties: record, type: string, additionalProperties: bool>>, publishedVersion: float, settings: record<csp: string, css: string, cssLinks: list<string>, customErrorScreenBrandLogoUrl: string, customErrorShowFooter: any, customFaviconLink: string, customLogoURLSelection: int, customTitle: string, defaultErrorScreenBrandLogo: any, flowHttpTimeoutInSeconds: int, flowTimeoutInSeconds: float, intermediateLoadingScreenCSS: any, intermediateLoadingScreenHTML: any, jsCustomFlowPlayer: string, jsLinks: list<record>, logLevel: int, requireAuthenticationToInitiate: any, scrubSensitiveInfo: any, sensitiveInfoFields: list<string>, useCSP: any, useCustomCSS: any, useCustomFlowPlayer: any, useCustomScript: any, useIntermediateLoadingScreen: any, validateOnSave: any>, trigger: record<type: string, configuration: record<mfa: record, pwd: record>>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/flows/($flowID)")
  let body = {name: $name, color: $color, description: $description, graphData: $graphData, inputSchema: $inputSchema, outputSchema: $outputSchema, settings: $settings, trigger: $trigger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /environments/{environmentID}/flows/{flowID}
#
# operationId: deleteFlowById
export def "environments-flows delete" [
  environmentID: string
  flowID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/flows/($flowID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /environments/{environmentID}/flows/{flowID}#clone+json
#
# operationId: cloneFlowByIdAsCloneJson
export def "environments-flows cloneFlowByIdAsCloneJson" [
  environmentID: string
  flowID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  --body: record
]: any -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, connectorInstances: record<href: string, name: string, profile: string, title: string, type: string>, connectors: record<href: string, name: string, profile: string, title: string, type: string>, flow_deploy: record<href: string, name: string, profile: string, title: string, type: string>, flow_clone: record<href: string, name: string, profile: string, title: string, type: string>, flow_enabled: record<href: string, name: string, profile: string, title: string, type: string>, version: record<href: string, name: string, profile: string, title: string, type: string>, flow_validate: record<href: string, name: string, profile: string, title: string, type: string>>, environment: record<id: string>, id: string, name: string, color: string, connectors: table<id: string>, createdAt: string, currentVersion: float, deployedAt: string, description: string, dvlinterErrorCount: float, dvlinterWarningCount: float, enabled: bool, graphData: record<boxSelectionEnabled: bool, elements: record<nodes: list, edges: list>, pan: record<x: float, y: float>, panningEnabled: bool, renderer: record<name: string>, userPanningEnabled: bool, userZoomingEnabled: bool, zoom: float, allLinterErrors: list<record>, data: record, maxZoom: float, minZoom: float, zoomingEnabled: bool>, inputSchema: table<preferredControlType: string, preferredDataType: string, propertyName: string, description: string, isExpanded: bool, required: bool>, outputSchema: record<output: record<properties: record, type: string, additionalProperties: bool>>, publishedVersion: float, settings: record<csp: string, css: string, cssLinks: list<string>, customErrorScreenBrandLogoUrl: string, customErrorShowFooter: any, customFaviconLink: string, customLogoURLSelection: int, customTitle: string, defaultErrorScreenBrandLogo: any, flowHttpTimeoutInSeconds: int, flowTimeoutInSeconds: float, intermediateLoadingScreenCSS: any, intermediateLoadingScreenHTML: any, jsCustomFlowPlayer: string, jsLinks: list<record>, logLevel: int, requireAuthenticationToInitiate: any, scrubSensitiveInfo: any, sensitiveInfoFields: list<string>, useCSP: any, useCustomCSS: any, useCustomFlowPlayer: any, useCustomScript: any, useIntermediateLoadingScreen: any, validateOnSave: any>, trigger: record<type: string, configuration: record<mfa: record, pwd: record>>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/flows/($flowID)#clone+json")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.pingidentity.flow.clone+json" $body
}

# POST /environments/{environmentID}/flows/{flowID}#deploy+json
#
# operationId: deployFlowByIdAsDeployJson
export def "environments-flows deployFlowByIdAsDeployJson" [
  environmentID: string
  flowID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  --body: record
]: any -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, connectorInstances: record<href: string, name: string, profile: string, title: string, type: string>, connectors: record<href: string, name: string, profile: string, title: string, type: string>, flow_deploy: record<href: string, name: string, profile: string, title: string, type: string>, flow_clone: record<href: string, name: string, profile: string, title: string, type: string>, flow_enabled: record<href: string, name: string, profile: string, title: string, type: string>, version: record<href: string, name: string, profile: string, title: string, type: string>, flow_validate: record<href: string, name: string, profile: string, title: string, type: string>>, environment: record<id: string>, id: string, name: string, color: string, connectors: table<id: string>, createdAt: string, currentVersion: float, deployedAt: string, description: string, dvlinterErrorCount: float, dvlinterWarningCount: float, enabled: bool, graphData: record<boxSelectionEnabled: bool, elements: record<nodes: list, edges: list>, pan: record<x: float, y: float>, panningEnabled: bool, renderer: record<name: string>, userPanningEnabled: bool, userZoomingEnabled: bool, zoom: float, allLinterErrors: list<record>, data: record, maxZoom: float, minZoom: float, zoomingEnabled: bool>, inputSchema: table<preferredControlType: string, preferredDataType: string, propertyName: string, description: string, isExpanded: bool, required: bool>, outputSchema: record<output: record<properties: record, type: string, additionalProperties: bool>>, publishedVersion: float, settings: record<csp: string, css: string, cssLinks: list<string>, customErrorScreenBrandLogoUrl: string, customErrorShowFooter: any, customFaviconLink: string, customLogoURLSelection: int, customTitle: string, defaultErrorScreenBrandLogo: any, flowHttpTimeoutInSeconds: int, flowTimeoutInSeconds: float, intermediateLoadingScreenCSS: any, intermediateLoadingScreenHTML: any, jsCustomFlowPlayer: string, jsLinks: list<record>, logLevel: int, requireAuthenticationToInitiate: any, scrubSensitiveInfo: any, sensitiveInfoFields: list<string>, useCSP: any, useCustomCSS: any, useCustomFlowPlayer: any, useCustomScript: any, useIntermediateLoadingScreen: any, validateOnSave: any>, trigger: record<type: string, configuration: record<mfa: record, pwd: record>>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/flows/($flowID)#deploy+json")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.pingidentity.flow.deploy+json" $body
}

# POST /environments/{environmentID}/flows/{flowID}#validate+json
#
# operationId: validateFlowByIdAsValidateJson
export def "environments-flows validateFlowByIdAsValidateJson" [
  environmentID: string
  flowID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  --body: record
]: any -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, connectorInstances: record<href: string, name: string, profile: string, title: string, type: string>, connectors: record<href: string, name: string, profile: string, title: string, type: string>, flow_deploy: record<href: string, name: string, profile: string, title: string, type: string>, flow_clone: record<href: string, name: string, profile: string, title: string, type: string>, flow_enabled: record<href: string, name: string, profile: string, title: string, type: string>, version: record<href: string, name: string, profile: string, title: string, type: string>, flow_validate: record<href: string, name: string, profile: string, title: string, type: string>>, environment: record<id: string>, id: string, name: string, color: string, connectors: table<id: string>, createdAt: string, currentVersion: float, deployedAt: string, description: string, dvlinterErrorCount: float, dvlinterWarningCount: float, enabled: bool, graphData: record<boxSelectionEnabled: bool, elements: record<nodes: list, edges: list>, pan: record<x: float, y: float>, panningEnabled: bool, renderer: record<name: string>, userPanningEnabled: bool, userZoomingEnabled: bool, zoom: float, allLinterErrors: list<record>, data: record, maxZoom: float, minZoom: float, zoomingEnabled: bool>, inputSchema: table<preferredControlType: string, preferredDataType: string, propertyName: string, description: string, isExpanded: bool, required: bool>, outputSchema: record<output: record<properties: record, type: string, additionalProperties: bool>>, publishedVersion: float, settings: record<csp: string, css: string, cssLinks: list<string>, customErrorScreenBrandLogoUrl: string, customErrorShowFooter: any, customFaviconLink: string, customLogoURLSelection: int, customTitle: string, defaultErrorScreenBrandLogo: any, flowHttpTimeoutInSeconds: int, flowTimeoutInSeconds: float, intermediateLoadingScreenCSS: any, intermediateLoadingScreenHTML: any, jsCustomFlowPlayer: string, jsLinks: list<record>, logLevel: int, requireAuthenticationToInitiate: any, scrubSensitiveInfo: any, sensitiveInfoFields: list<string>, useCSP: any, useCustomCSS: any, useCustomFlowPlayer: any, useCustomScript: any, useIntermediateLoadingScreen: any, validateOnSave: any>, trigger: record<type: string, configuration: record<mfa: record, pwd: record>>, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/flows/($flowID)#validate+json")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/vnd.pingidentity.flow.validate+json" $body
}

# PUT /environments/{environmentID}/flows/{flowID}/enabled
#
# operationId: updateEnabledByFlowId
export def "environments-flows-enabled updateEnabledByFlowId" [
  environmentID: string
  flowID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  --enabled: oneof<nothing, bool>
]: any -> record<_links: record<self: record<href: string, name: string, profile: string, title: string, type: string>>, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/flows/($flowID)/enabled")
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /environments/{environmentID}/flows/{flowID}/versions
#
# operationId: getVersionsByFlowId
export def "environments-flows-versions list" [
  environmentID: string
  flowID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_embedded: record<versions: list<record>>, _links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/flows/($flowID)/versions")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/flows/{flowID}/versions/{versionID}
#
# operationId: getVersionByIdUsingFlowId
export def "environments-flows-versions get" [
  environmentID: string
  flowID: string
  versionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, details: record<href: string, name: string, profile: string, title: string, type: string>, flow_export: record<href: string, name: string, profile: string, title: string, type: string>, flow_revert: record<href: string, name: string, profile: string, title: string, type: string>>, environment: record<id: string>, flow: record<id: string, name: string>, version: float, alias: string, clonedFrom: float, createdAt: string, deployedAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/flows/($flowID)/versions/($versionID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /environments/{environmentID}/flows/{flowID}/versions/{versionID}
#
# operationId: deleteVersionByIdUsingFlowId
export def "environments-flows-versions delete" [
  environmentID: string
  flowID: string
  versionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/flows/($flowID)/versions/($versionID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /environments/{environmentID}/flows/{flowID}/versions/{versionID}/alias
#
# operationId: replaceAliasByFlowIdAndVersionId
export def "environments-flows-versions-alias replaceAliasByFlowIdAndVersionId" [
  environmentID: string
  flowID: string
  versionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  alias: string
]: any -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, flowVersion: record<href: string, name: string, profile: string, title: string, type: string>>, alias: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/flows/($flowID)/versions/($versionID)/alias")
  let body = {alias: $alias} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /environments/{environmentID}/flows/{flowID}/versions/{versionID}/details
#
# operationId: getDetailsByFlowIdAndVersionId
export def "environments-flows-versions-details get" [
  environmentID: string
  flowID: string
  versionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, flow_export: record<href: string, name: string, profile: string, title: string, type: string>, flow_revert: record<href: string, name: string, profile: string, title: string, type: string>, connectorInstances__nodeId_: record<href: string, name: string, profile: string, title: string, type: string>, variables__nodeId___index_: record<href: string, name: string, profile: string, title: string, type: string>>, alias: string, color: string, connectors: table<id: string>, createdAt: string, deployedAt: string, description: string, enabled: bool, flow: record<id: string, name: string>, graphData: record<boxSelectionEnabled: bool, elements: record<nodes: list, edges: list>, pan: record<x: float, y: float>, panningEnabled: bool, renderer: record<name: string>, userPanningEnabled: bool, userZoomingEnabled: bool, zoom: float, allLinterErrors: list<record>, data: record, maxZoom: float, minZoom: float, zoomingEnabled: bool>, inputSchema: table<preferredControlType: string, preferredDataType: string, propertyName: string, description: string, isExpanded: bool, required: bool>, outputSchema: record<output: record<properties: record, type: string, additionalProperties: bool>>, settings: record<csp: string, css: string, cssLinks: list<string>, customErrorScreenBrandLogoUrl: string, customErrorShowFooter: any, customFaviconLink: string, customLogoURLSelection: int, customTitle: string, defaultErrorScreenBrandLogo: any, flowHttpTimeoutInSeconds: int, flowTimeoutInSeconds: float, intermediateLoadingScreenCSS: any, intermediateLoadingScreenHTML: any, jsCustomFlowPlayer: string, jsLinks: list<record>, logLevel: int, requireAuthenticationToInitiate: any, scrubSensitiveInfo: any, sensitiveInfoFields: list<string>, useCSP: any, useCustomCSS: any, useCustomFlowPlayer: any, useCustomScript: any, useIntermediateLoadingScreen: any, validateOnSave: any>, skcomponents: table<id: string, name: string, nodeId: string, options: record>, trigger: record<type: string, configuration: record<mfa: record, pwd: record>>, updatedAt: string, updates: list<string>, version: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/environments/($environmentID)/flows/($flowID)/versions/($versionID)/details" $qp)
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /environments/{environmentID}/snapshots
#
# operationId: createSnapshot
export def "environments-snapshots createSnapshot" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  baseResourceURL: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/environments/($environmentID)/snapshots" $qp)
  let body = {baseResourceURL: $baseResourceURL} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /environments/{environmentID}/snapshots/{snapshotID}
#
# operationId: getSnapshotById
export def "environments-snapshots get" [
  environmentID: string
  snapshotID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string
  --filter: string
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/environments/($environmentID)/snapshots/($snapshotID)" $qp)
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/snapshots/{snapshotID}/versions
#
# operationId: getVersionsBySnapshotId
export def "environments-snapshots-versions list" [
  environmentID: string
  snapshotID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_embedded: record<versions: list<record>>, _links: record<self: record<href: string, name: string, profile: string, title: string, type: string>>, count: int, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/snapshots/($snapshotID)/versions")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/snapshots/{snapshotID}/versions/{versionID}
#
# operationId: getVersionByIdUsingSnapshotId
export def "environments-snapshots-versions get" [
  environmentID: string
  snapshotID: string
  versionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string
  --attributes: string
  --filter: string
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "attributes" $attributes "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/environments/($environmentID)/snapshots/($snapshotID)/versions/($versionID)" $qp)
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/totalIdentities
#
# operationId: getTotalIdentities
export def "environments-total-identities get" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --filter: string
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_embedded: record<totalIdentities: list<record>>, _links: record<self: record<href: string, name: string, profile: string, title: string, type: string>>, count: int, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/environments/($environmentID)/totalIdentities" $qp)
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/hal+json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /environments/{environmentID}/variables
#
# operationId: getVariables
export def "environments-variables list" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # format: int32, default: 10
  --cursor: string
  --filter: string
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_embedded: record<variables: list<record>>, _links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>, next: record<href: string, name: string, profile: string, title: string, type: string>>, size: float, count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/environments/($environmentID)/variables" $qp)
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /environments/{environmentID}/variables
#
# operationId: createVariable
# --flow shape: {id: string}
export def "environments-variables createVariable" [
  environmentID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  name: string
  context: string@context-completer
  dataType: string@dataType-completer
  --mutable: oneof<nothing, bool>
  --displayName: string
  --flow: record # shape: {id: string}
  --max: int # default: 2000
  --min: int # default: 0
  --value: any
]: any -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>>, dataType: string, environment: record<id: string>, id: string, name: string, context: string, createdAt: string, displayName: string, flow: record<id: string>, max: float, min: float, mutable: bool, updatedAt: string, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/variables")
  let body = {name: $name, context: $context, dataType: $dataType, mutable: $mutable, displayName: $displayName, flow: $flow, max: $max, min: $min, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /environments/{environmentID}/variables/{variableID}
#
# operationId: getVariableById
export def "environments-variables get" [
  environmentID: string
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>>, dataType: string, environment: record<id: string>, id: string, name: string, context: string, createdAt: string, displayName: string, flow: record<id: string>, max: float, min: float, mutable: bool, updatedAt: string, value: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/variables/($variableID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /environments/{environmentID}/variables/{variableID}
#
# operationId: replaceVariableById
# --flow shape: {id: string}
export def "environments-variables replaceVariableById" [
  environmentID: string
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
  name: string
  context: string@context-completer
  dataType: string@dataType-completer
  --mutable: oneof<nothing, bool>
  --displayName: string
  --flow: record # shape: {id: string}
  --max: int # default: 2000
  --min: int # default: 0
  --value: any
]: any -> record<_links: record<environment: record<href: string, name: string, profile: string, title: string, type: string>, self: record<href: string, name: string, profile: string, title: string, type: string>>, dataType: string, environment: record<id: string>, id: string, name: string, context: string, createdAt: string, displayName: string, flow: record<id: string>, max: float, min: float, mutable: bool, updatedAt: string, value: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/variables/($variableID)")
  let body = {name: $name, context: $context, dataType: $dataType, mutable: $mutable, displayName: $displayName, flow: $flow, max: $max, min: $min, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /environments/{environmentID}/variables/{variableID}
#
# operationId: deleteVariableById
export def "environments-variables delete" [
  environmentID: string
  variableID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Ping-External-Session-ID: string
  --X-Ping-External-Transaction-ID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/environments/($environmentID)/variables/($variableID)")
  let extra_headers = {"X-Ping-External-Session-ID": $X_Ping_External_Session_ID, "X-Ping-External-Transaction-ID": $X_Ping_External_Transaction_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
