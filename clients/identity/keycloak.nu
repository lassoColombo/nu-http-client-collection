# Auto-generated client for Keycloak Admin REST API v1
# Source: https://api.apis.guru/v2/specs/keycloak.local/1/openapi.json
# Auth: --token flag or $env.KEYCLOAK_ADMIN_REST_API_TOKEN

const BASE_URL = "http://keycloak.local"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KEYCLOAK_ADMIN_REST_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://keycloak.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def policy-completer [] { ["FAIL" "OVERWRITE" "SKIP"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "root get" } } | get name | first)
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

# Get themes, social providers, auth providers, and event listeners available on this server
#
# GET /
export def "root get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<builtinProtocolMappers: record, clientImporters: list<record>, clientInstallations: record, componentTypes: record, enums: record, identityProviders: list<record>, memoryInfo: record<free: int, freeFormated: string, freePercentage: int, total: int, totalFormated: string, used: int, usedFormated: string>, passwordPolicies: table<configType: string, defaultValue: string, displayName: string, id: string, multipleSupported: bool>, profileInfo: record<disabledFeatures: list<string>, experimentalFeatures: list<string>, name: string, previewFeatures: list<string>>, protocolMapperTypes: record, providers: record, socialProviders: list<record>, systemInfo: record<fileEncoding: string, javaHome: string, javaRuntime: string, javaVendor: string, javaVersion: string, javaVm: string, javaVmVersion: string, osArchitecture: string, osName: string, osVersion: string, serverTime: string, uptime: string, uptimeMillis: int, userDir: string, userLocale: string, userName: string, userTimezone: string, version: string>, themes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import a realm   Imports a realm from a full representation of that realm.
#
# POST /
# --authenticationFlows item shape: {alias?: string, authenticationExecutions?: list, builtIn?: bool, description?: string, id?: string, providerId?: string, topLevel?: bool}
# --authenticatorConfig item shape: {alias?: string, config?: record, id?: string}
# --clientScopes item shape: {attributes?: record, description?: string, id?: string, name?: string, protocol?: string, protocolMappers?: list}
# --clients item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list, defaultRoles?: list, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, fullScopeAllowed?: bool, id?: string, implicitFlowEnabled?: bool, name?: string, nodeReRegistrationTimeout?: int, notBefore?: int, optionalClientScopes?: list, origin?: string, protocol?: string, protocolMappers?: list, publicClient?: bool, redirectUris?: list, registeredNodes?: record, registrationAccessToken?: string, rootUrl?: string, secret?: string, serviceAccountsEnabled?: bool, standardFlowEnabled?: bool, surrogateAuthRequired?: bool, webOrigins?: list}
# --components shape: {empty?: bool, loadFactor?: float, threshold?: int}
# --federatedUsers item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list, requiredActions?: list, self?: string, serviceAccountClientId?: string, username?: string}
# --groups item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list, subGroups?: list}
# --identityProviderMappers item shape: {config?: record, id?: string, identityProviderAlias?: string, identityProviderMapper?: string, name?: string}
# --identityProviders item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
# --protocolMappers item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
# --requiredActions item shape: {alias?: string, config?: record, defaultAction?: bool, enabled?: bool, name?: string, priority?: int, providerId?: string}
# --roles shape: {client?: record, realm?: list}
# --scopeMappings item shape: {client?: string, clientScope?: string, roles?: list, self?: string}
# --userFederationMappers item shape: {config?: record, federationMapperType?: string, federationProviderDisplayName?: string, id?: string, name?: string}
# --userFederationProviders item shape: {changedSyncPeriod?: int, config?: record, displayName?: string, fullSyncPeriod?: int, id?: string, lastSync?: int, priority?: int, providerName?: string}
# --users item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list, requiredActions?: list, self?: string, serviceAccountClientId?: string, username?: string}
export def "realms-admin post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessCodeLifespan: int # format: int32
  --accessCodeLifespanLogin: int # format: int32
  --accessCodeLifespanUserAction: int # format: int32
  --accessTokenLifespan: int # format: int32
  --accessTokenLifespanForImplicitFlow: int # format: int32
  --accountTheme: string
  --actionTokenGeneratedByAdminLifespan: int # format: int32
  --actionTokenGeneratedByUserLifespan: int # format: int32
  --adminEventsDetailsEnabled: oneof<nothing, bool>
  --adminEventsEnabled: oneof<nothing, bool>
  --adminTheme: string
  --attributes: record
  --authenticationFlows: list # item shape: {alias?: string, authenticationExecutions?: list, builtIn?: bool, description?: string, id?: string, providerId?: string, topLevel?: bool}
  --authenticatorConfig: list # item shape: {alias?: string, config?: record, id?: string}
  --browserFlow: string
  --browserSecurityHeaders: record
  --bruteForceProtected: oneof<nothing, bool>
  --clientAuthenticationFlow: string
  --clientScopeMappings: record
  --clientScopes: list # item shape: {attributes?: record, description?: string, id?: string, name?: string, protocol?: string, protocolMappers?: list}
  --clientSessionIdleTimeout: int # format: int32
  --clientSessionMaxLifespan: int # format: int32
  --clients: list # item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list, defaultRoles?: list, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, fullScopeAllowed?: bool, id?: string, implicitFlowEnabled?: bool, name?: string, nodeReRegistrationTimeout?: int, notBefore?: int, optionalClientScopes?: list, origin?: string, protocol?: string, protocolMappers?: list, publicClient?: bool, redirectUris?: list, registeredNodes?: record, registrationAccessToken?: string, rootUrl?: string, secret?: string, serviceAccountsEnabled?: bool, standardFlowEnabled?: bool, surrogateAuthRequired?: bool, webOrigins?: list}
  --components: record # shape: {empty?: bool, loadFactor?: float, threshold?: int}
  --defaultDefaultClientScopes: list
  --defaultGroups: list
  --defaultLocale: string
  --defaultOptionalClientScopes: list
  --defaultRoles: list
  --defaultSignatureAlgorithm: string
  --directGrantFlow: string
  --displayName: string
  --displayNameHtml: string
  --dockerAuthenticationFlow: string
  --duplicateEmailsAllowed: oneof<nothing, bool>
  --editUsernameAllowed: oneof<nothing, bool>
  --emailTheme: string
  --enabled: oneof<nothing, bool>
  --enabledEventTypes: list
  --eventsEnabled: oneof<nothing, bool>
  --eventsExpiration: int # format: int64
  --eventsListeners: list
  --failureFactor: int # format: int32
  --federatedUsers: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list, requiredActions?: list, self?: string, serviceAccountClientId?: string, username?: string}
  --groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list, subGroups?: list}
  --id: string
  --identityProviderMappers: list # item shape: {config?: record, id?: string, identityProviderAlias?: string, identityProviderMapper?: string, name?: string}
  --identityProviders: list # item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
  --internationalizationEnabled: oneof<nothing, bool>
  --keycloakVersion: string
  --loginTheme: string
  --loginWithEmailAllowed: oneof<nothing, bool>
  --maxDeltaTimeSeconds: int # format: int32
  --maxFailureWaitSeconds: int # format: int32
  --minimumQuickLoginWaitSeconds: int # format: int32
  --notBefore: int # format: int32
  --offlineSessionIdleTimeout: int # format: int32
  --offlineSessionMaxLifespan: int # format: int32
  --offlineSessionMaxLifespanEnabled: oneof<nothing, bool>
  --otpPolicyAlgorithm: string
  --otpPolicyDigits: int # format: int32
  --otpPolicyInitialCounter: int # format: int32
  --otpPolicyLookAheadWindow: int # format: int32
  --otpPolicyPeriod: int # format: int32
  --otpPolicyType: string
  --otpSupportedApplications: list
  --passwordPolicy: string
  --permanentLockout: oneof<nothing, bool>
  --protocolMappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
  --quickLoginCheckMilliSeconds: int # format: int64
  --realm: string
  --refreshTokenMaxReuse: int # format: int32
  --registrationAllowed: oneof<nothing, bool>
  --registrationEmailAsUsername: oneof<nothing, bool>
  --registrationFlow: string
  --rememberMe: oneof<nothing, bool>
  --requiredActions: list # item shape: {alias?: string, config?: record, defaultAction?: bool, enabled?: bool, name?: string, priority?: int, providerId?: string}
  --resetCredentialsFlow: string
  --resetPasswordAllowed: oneof<nothing, bool>
  --revokeRefreshToken: oneof<nothing, bool>
  --roles: record # shape: {client?: record, realm?: list}
  --scopeMappings: list # item shape: {client?: string, clientScope?: string, roles?: list, self?: string}
  --smtpServer: record
  --sslRequired: string
  --ssoSessionIdleTimeout: int # format: int32
  --ssoSessionIdleTimeoutRememberMe: int # format: int32
  --ssoSessionMaxLifespan: int # format: int32
  --ssoSessionMaxLifespanRememberMe: int # format: int32
  --supportedLocales: list
  --userFederationMappers: list # item shape: {config?: record, federationMapperType?: string, federationProviderDisplayName?: string, id?: string, name?: string}
  --userFederationProviders: list # item shape: {changedSyncPeriod?: int, config?: record, displayName?: string, fullSyncPeriod?: int, id?: string, lastSync?: int, priority?: int, providerName?: string}
  --userManagedAccessAllowed: oneof<nothing, bool>
  --users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list, requiredActions?: list, self?: string, serviceAccountClientId?: string, username?: string}
  --verifyEmail: oneof<nothing, bool>
  --waitIncrementSeconds: int # format: int32
  --webAuthnPolicyAcceptableAaguids: list
  --webAuthnPolicyAttestationConveyancePreference: string
  --webAuthnPolicyAuthenticatorAttachment: string
  --webAuthnPolicyAvoidSameAuthenticatorRegister: oneof<nothing, bool>
  --webAuthnPolicyCreateTimeout: int # format: int32
  --webAuthnPolicyPasswordlessAcceptableAaguids: list
  --webAuthnPolicyPasswordlessAttestationConveyancePreference: string
  --webAuthnPolicyPasswordlessAuthenticatorAttachment: string
  --webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister: oneof<nothing, bool>
  --webAuthnPolicyPasswordlessCreateTimeout: int # format: int32
  --webAuthnPolicyPasswordlessRequireResidentKey: string
  --webAuthnPolicyPasswordlessRpEntityName: string
  --webAuthnPolicyPasswordlessRpId: string
  --webAuthnPolicyPasswordlessSignatureAlgorithms: list
  --webAuthnPolicyPasswordlessUserVerificationRequirement: string
  --webAuthnPolicyRequireResidentKey: string
  --webAuthnPolicyRpEntityName: string
  --webAuthnPolicyRpId: string
  --webAuthnPolicySignatureAlgorithms: list
  --webAuthnPolicyUserVerificationRequirement: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let body = {accessCodeLifespan: $accessCodeLifespan, accessCodeLifespanLogin: $accessCodeLifespanLogin, accessCodeLifespanUserAction: $accessCodeLifespanUserAction, accessTokenLifespan: $accessTokenLifespan, accessTokenLifespanForImplicitFlow: $accessTokenLifespanForImplicitFlow, accountTheme: $accountTheme, actionTokenGeneratedByAdminLifespan: $actionTokenGeneratedByAdminLifespan, actionTokenGeneratedByUserLifespan: $actionTokenGeneratedByUserLifespan, adminEventsDetailsEnabled: $adminEventsDetailsEnabled, adminEventsEnabled: $adminEventsEnabled, adminTheme: $adminTheme, attributes: $attributes, authenticationFlows: $authenticationFlows, authenticatorConfig: $authenticatorConfig, browserFlow: $browserFlow, browserSecurityHeaders: $browserSecurityHeaders, bruteForceProtected: $bruteForceProtected, clientAuthenticationFlow: $clientAuthenticationFlow, clientScopeMappings: $clientScopeMappings, clientScopes: $clientScopes, clientSessionIdleTimeout: $clientSessionIdleTimeout, clientSessionMaxLifespan: $clientSessionMaxLifespan, clients: $clients, components: $components, defaultDefaultClientScopes: $defaultDefaultClientScopes, defaultGroups: $defaultGroups, defaultLocale: $defaultLocale, defaultOptionalClientScopes: $defaultOptionalClientScopes, defaultRoles: $defaultRoles, defaultSignatureAlgorithm: $defaultSignatureAlgorithm, directGrantFlow: $directGrantFlow, displayName: $displayName, displayNameHtml: $displayNameHtml, dockerAuthenticationFlow: $dockerAuthenticationFlow, duplicateEmailsAllowed: $duplicateEmailsAllowed, editUsernameAllowed: $editUsernameAllowed, emailTheme: $emailTheme, enabled: $enabled, enabledEventTypes: $enabledEventTypes, eventsEnabled: $eventsEnabled, eventsExpiration: $eventsExpiration, eventsListeners: $eventsListeners, failureFactor: $failureFactor, federatedUsers: $federatedUsers, groups: $groups, id: $id, identityProviderMappers: $identityProviderMappers, identityProviders: $identityProviders, internationalizationEnabled: $internationalizationEnabled, keycloakVersion: $keycloakVersion, loginTheme: $loginTheme, loginWithEmailAllowed: $loginWithEmailAllowed, maxDeltaTimeSeconds: $maxDeltaTimeSeconds, maxFailureWaitSeconds: $maxFailureWaitSeconds, minimumQuickLoginWaitSeconds: $minimumQuickLoginWaitSeconds, notBefore: $notBefore, offlineSessionIdleTimeout: $offlineSessionIdleTimeout, offlineSessionMaxLifespan: $offlineSessionMaxLifespan, offlineSessionMaxLifespanEnabled: $offlineSessionMaxLifespanEnabled, otpPolicyAlgorithm: $otpPolicyAlgorithm, otpPolicyDigits: $otpPolicyDigits, otpPolicyInitialCounter: $otpPolicyInitialCounter, otpPolicyLookAheadWindow: $otpPolicyLookAheadWindow, otpPolicyPeriod: $otpPolicyPeriod, otpPolicyType: $otpPolicyType, otpSupportedApplications: $otpSupportedApplications, passwordPolicy: $passwordPolicy, permanentLockout: $permanentLockout, protocolMappers: $protocolMappers, quickLoginCheckMilliSeconds: $quickLoginCheckMilliSeconds, realm: $realm, refreshTokenMaxReuse: $refreshTokenMaxReuse, registrationAllowed: $registrationAllowed, registrationEmailAsUsername: $registrationEmailAsUsername, registrationFlow: $registrationFlow, rememberMe: $rememberMe, requiredActions: $requiredActions, resetCredentialsFlow: $resetCredentialsFlow, resetPasswordAllowed: $resetPasswordAllowed, revokeRefreshToken: $revokeRefreshToken, roles: $roles, scopeMappings: $scopeMappings, smtpServer: $smtpServer, sslRequired: $sslRequired, ssoSessionIdleTimeout: $ssoSessionIdleTimeout, ssoSessionIdleTimeoutRememberMe: $ssoSessionIdleTimeoutRememberMe, ssoSessionMaxLifespan: $ssoSessionMaxLifespan, ssoSessionMaxLifespanRememberMe: $ssoSessionMaxLifespanRememberMe, supportedLocales: $supportedLocales, userFederationMappers: $userFederationMappers, userFederationProviders: $userFederationProviders, userManagedAccessAllowed: $userManagedAccessAllowed, users: $users, verifyEmail: $verifyEmail, waitIncrementSeconds: $waitIncrementSeconds, webAuthnPolicyAcceptableAaguids: $webAuthnPolicyAcceptableAaguids, webAuthnPolicyAttestationConveyancePreference: $webAuthnPolicyAttestationConveyancePreference, webAuthnPolicyAuthenticatorAttachment: $webAuthnPolicyAuthenticatorAttachment, webAuthnPolicyAvoidSameAuthenticatorRegister: $webAuthnPolicyAvoidSameAuthenticatorRegister, webAuthnPolicyCreateTimeout: $webAuthnPolicyCreateTimeout, webAuthnPolicyPasswordlessAcceptableAaguids: $webAuthnPolicyPasswordlessAcceptableAaguids, webAuthnPolicyPasswordlessAttestationConveyancePreference: $webAuthnPolicyPasswordlessAttestationConveyancePreference, webAuthnPolicyPasswordlessAuthenticatorAttachment: $webAuthnPolicyPasswordlessAuthenticatorAttachment, webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister: $webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister, webAuthnPolicyPasswordlessCreateTimeout: $webAuthnPolicyPasswordlessCreateTimeout, webAuthnPolicyPasswordlessRequireResidentKey: $webAuthnPolicyPasswordlessRequireResidentKey, webAuthnPolicyPasswordlessRpEntityName: $webAuthnPolicyPasswordlessRpEntityName, webAuthnPolicyPasswordlessRpId: $webAuthnPolicyPasswordlessRpId, webAuthnPolicyPasswordlessSignatureAlgorithms: $webAuthnPolicyPasswordlessSignatureAlgorithms, webAuthnPolicyPasswordlessUserVerificationRequirement: $webAuthnPolicyPasswordlessUserVerificationRequirement, webAuthnPolicyRequireResidentKey: $webAuthnPolicyRequireResidentKey, webAuthnPolicyRpEntityName: $webAuthnPolicyRpEntityName, webAuthnPolicyRpId: $webAuthnPolicyRpId, webAuthnPolicySignatureAlgorithms: $webAuthnPolicySignatureAlgorithms, webAuthnPolicyUserVerificationRequirement: $webAuthnPolicyUserVerificationRequirement} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Need this for admin console to display simple name of provider when displaying client detail   KEYCLOAK-4328
#
# GET /{id}/name
export def "name get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($id)/name")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the realm
#
# DELETE /{realm}
export def "realms-admin delete" [
  realm: string
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
  let full_url = (build-url $base $"/($realm)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the top-level representation of the realm   It will not include nested information like User and Client representations.
#
# GET /{realm}
export def "realms-admin get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accessCodeLifespan: int, accessCodeLifespanLogin: int, accessCodeLifespanUserAction: int, accessTokenLifespan: int, accessTokenLifespanForImplicitFlow: int, accountTheme: string, actionTokenGeneratedByAdminLifespan: int, actionTokenGeneratedByUserLifespan: int, adminEventsDetailsEnabled: bool, adminEventsEnabled: bool, adminTheme: string, attributes: record, authenticationFlows: table<alias: string, authenticationExecutions: list, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool>, authenticatorConfig: table<alias: string, config: record, id: string>, browserFlow: string, browserSecurityHeaders: record, bruteForceProtected: bool, clientAuthenticationFlow: string, clientScopeMappings: record, clientScopes: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list>, clientSessionIdleTimeout: int, clientSessionMaxLifespan: int, clients: table<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list, defaultRoles: list, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list, origin: string, protocol: string, protocolMappers: list, publicClient: bool, redirectUris: list, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list>, components: record<empty: bool, loadFactor: float, threshold: int>, defaultDefaultClientScopes: list<string>, defaultGroups: list<string>, defaultLocale: string, defaultOptionalClientScopes: list<string>, defaultRoles: list<string>, defaultSignatureAlgorithm: string, directGrantFlow: string, displayName: string, displayNameHtml: string, dockerAuthenticationFlow: string, duplicateEmailsAllowed: bool, editUsernameAllowed: bool, emailTheme: string, enabled: bool, enabledEventTypes: list<string>, eventsEnabled: bool, eventsExpiration: int, eventsListeners: list<string>, failureFactor: int, federatedUsers: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, groups: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list, subGroups: list>, id: string, identityProviderMappers: table<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string>, identityProviders: table<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool>, internationalizationEnabled: bool, keycloakVersion: string, loginTheme: string, loginWithEmailAllowed: bool, maxDeltaTimeSeconds: int, maxFailureWaitSeconds: int, minimumQuickLoginWaitSeconds: int, notBefore: int, offlineSessionIdleTimeout: int, offlineSessionMaxLifespan: int, offlineSessionMaxLifespanEnabled: bool, otpPolicyAlgorithm: string, otpPolicyDigits: int, otpPolicyInitialCounter: int, otpPolicyLookAheadWindow: int, otpPolicyPeriod: int, otpPolicyType: string, otpSupportedApplications: list<string>, passwordPolicy: string, permanentLockout: bool, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, quickLoginCheckMilliSeconds: int, realm: string, refreshTokenMaxReuse: int, registrationAllowed: bool, registrationEmailAsUsername: bool, registrationFlow: string, rememberMe: bool, requiredActions: table<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string>, resetCredentialsFlow: string, resetPasswordAllowed: bool, revokeRefreshToken: bool, roles: record<client: record, realm: list<record>>, scopeMappings: table<client: string, clientScope: string, roles: list, self: string>, smtpServer: record, sslRequired: string, ssoSessionIdleTimeout: int, ssoSessionIdleTimeoutRememberMe: int, ssoSessionMaxLifespan: int, ssoSessionMaxLifespanRememberMe: int, supportedLocales: list<string>, userFederationMappers: table<config: record, federationMapperType: string, federationProviderDisplayName: string, id: string, name: string>, userFederationProviders: table<changedSyncPeriod: int, config: record, displayName: string, fullSyncPeriod: int, id: string, lastSync: int, priority: int, providerName: string>, userManagedAccessAllowed: bool, users: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, verifyEmail: bool, waitIncrementSeconds: int, webAuthnPolicyAcceptableAaguids: list<string>, webAuthnPolicyAttestationConveyancePreference: string, webAuthnPolicyAuthenticatorAttachment: string, webAuthnPolicyAvoidSameAuthenticatorRegister: bool, webAuthnPolicyCreateTimeout: int, webAuthnPolicyPasswordlessAcceptableAaguids: list<string>, webAuthnPolicyPasswordlessAttestationConveyancePreference: string, webAuthnPolicyPasswordlessAuthenticatorAttachment: string, webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister: bool, webAuthnPolicyPasswordlessCreateTimeout: int, webAuthnPolicyPasswordlessRequireResidentKey: string, webAuthnPolicyPasswordlessRpEntityName: string, webAuthnPolicyPasswordlessRpId: string, webAuthnPolicyPasswordlessSignatureAlgorithms: list<string>, webAuthnPolicyPasswordlessUserVerificationRequirement: string, webAuthnPolicyRequireResidentKey: string, webAuthnPolicyRpEntityName: string, webAuthnPolicyRpId: string, webAuthnPolicySignatureAlgorithms: list<string>, webAuthnPolicyUserVerificationRequirement: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the top-level information of the realm   Any user, roles or client information in the representation  will be ignored.
#
# PUT /{realm}
# --authenticationFlows item shape: {alias?: string, authenticationExecutions?: list, builtIn?: bool, description?: string, id?: string, providerId?: string, topLevel?: bool}
# --authenticatorConfig item shape: {alias?: string, config?: record, id?: string}
# --clientScopes item shape: {attributes?: record, description?: string, id?: string, name?: string, protocol?: string, protocolMappers?: list}
# --clients item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list, defaultRoles?: list, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, fullScopeAllowed?: bool, id?: string, implicitFlowEnabled?: bool, name?: string, nodeReRegistrationTimeout?: int, notBefore?: int, optionalClientScopes?: list, origin?: string, protocol?: string, protocolMappers?: list, publicClient?: bool, redirectUris?: list, registeredNodes?: record, registrationAccessToken?: string, rootUrl?: string, secret?: string, serviceAccountsEnabled?: bool, standardFlowEnabled?: bool, surrogateAuthRequired?: bool, webOrigins?: list}
# --components shape: {empty?: bool, loadFactor?: float, threshold?: int}
# --federatedUsers item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list, requiredActions?: list, self?: string, serviceAccountClientId?: string, username?: string}
# --groups item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list, subGroups?: list}
# --identityProviderMappers item shape: {config?: record, id?: string, identityProviderAlias?: string, identityProviderMapper?: string, name?: string}
# --identityProviders item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
# --protocolMappers item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
# --requiredActions item shape: {alias?: string, config?: record, defaultAction?: bool, enabled?: bool, name?: string, priority?: int, providerId?: string}
# --roles shape: {client?: record, realm?: list}
# --scopeMappings item shape: {client?: string, clientScope?: string, roles?: list, self?: string}
# --userFederationMappers item shape: {config?: record, federationMapperType?: string, federationProviderDisplayName?: string, id?: string, name?: string}
# --userFederationProviders item shape: {changedSyncPeriod?: int, config?: record, displayName?: string, fullSyncPeriod?: int, id?: string, lastSync?: int, priority?: int, providerName?: string}
# --users item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list, requiredActions?: list, self?: string, serviceAccountClientId?: string, username?: string}
export def "realms-admin put" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accessCodeLifespan: int # format: int32
  --accessCodeLifespanLogin: int # format: int32
  --accessCodeLifespanUserAction: int # format: int32
  --accessTokenLifespan: int # format: int32
  --accessTokenLifespanForImplicitFlow: int # format: int32
  --accountTheme: string
  --actionTokenGeneratedByAdminLifespan: int # format: int32
  --actionTokenGeneratedByUserLifespan: int # format: int32
  --adminEventsDetailsEnabled: oneof<nothing, bool>
  --adminEventsEnabled: oneof<nothing, bool>
  --adminTheme: string
  --attributes: record
  --authenticationFlows: list # item shape: {alias?: string, authenticationExecutions?: list, builtIn?: bool, description?: string, id?: string, providerId?: string, topLevel?: bool}
  --authenticatorConfig: list # item shape: {alias?: string, config?: record, id?: string}
  --browserFlow: string
  --browserSecurityHeaders: record
  --bruteForceProtected: oneof<nothing, bool>
  --clientAuthenticationFlow: string
  --clientScopeMappings: record
  --clientScopes: list # item shape: {attributes?: record, description?: string, id?: string, name?: string, protocol?: string, protocolMappers?: list}
  --clientSessionIdleTimeout: int # format: int32
  --clientSessionMaxLifespan: int # format: int32
  --clients: list # item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list, defaultRoles?: list, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, fullScopeAllowed?: bool, id?: string, implicitFlowEnabled?: bool, name?: string, nodeReRegistrationTimeout?: int, notBefore?: int, optionalClientScopes?: list, origin?: string, protocol?: string, protocolMappers?: list, publicClient?: bool, redirectUris?: list, registeredNodes?: record, registrationAccessToken?: string, rootUrl?: string, secret?: string, serviceAccountsEnabled?: bool, standardFlowEnabled?: bool, surrogateAuthRequired?: bool, webOrigins?: list}
  --components: record # shape: {empty?: bool, loadFactor?: float, threshold?: int}
  --defaultDefaultClientScopes: list
  --defaultGroups: list
  --defaultLocale: string
  --defaultOptionalClientScopes: list
  --defaultRoles: list
  --defaultSignatureAlgorithm: string
  --directGrantFlow: string
  --displayName: string
  --displayNameHtml: string
  --dockerAuthenticationFlow: string
  --duplicateEmailsAllowed: oneof<nothing, bool>
  --editUsernameAllowed: oneof<nothing, bool>
  --emailTheme: string
  --enabled: oneof<nothing, bool>
  --enabledEventTypes: list
  --eventsEnabled: oneof<nothing, bool>
  --eventsExpiration: int # format: int64
  --eventsListeners: list
  --failureFactor: int # format: int32
  --federatedUsers: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list, requiredActions?: list, self?: string, serviceAccountClientId?: string, username?: string}
  --groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list, subGroups?: list}
  --id: string
  --identityProviderMappers: list # item shape: {config?: record, id?: string, identityProviderAlias?: string, identityProviderMapper?: string, name?: string}
  --identityProviders: list # item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
  --internationalizationEnabled: oneof<nothing, bool>
  --keycloakVersion: string
  --loginTheme: string
  --loginWithEmailAllowed: oneof<nothing, bool>
  --maxDeltaTimeSeconds: int # format: int32
  --maxFailureWaitSeconds: int # format: int32
  --minimumQuickLoginWaitSeconds: int # format: int32
  --notBefore: int # format: int32
  --offlineSessionIdleTimeout: int # format: int32
  --offlineSessionMaxLifespan: int # format: int32
  --offlineSessionMaxLifespanEnabled: oneof<nothing, bool>
  --otpPolicyAlgorithm: string
  --otpPolicyDigits: int # format: int32
  --otpPolicyInitialCounter: int # format: int32
  --otpPolicyLookAheadWindow: int # format: int32
  --otpPolicyPeriod: int # format: int32
  --otpPolicyType: string
  --otpSupportedApplications: list
  --passwordPolicy: string
  --permanentLockout: oneof<nothing, bool>
  --protocolMappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
  --quickLoginCheckMilliSeconds: int # format: int64
  --body-realm: string
  --refreshTokenMaxReuse: int # format: int32
  --registrationAllowed: oneof<nothing, bool>
  --registrationEmailAsUsername: oneof<nothing, bool>
  --registrationFlow: string
  --rememberMe: oneof<nothing, bool>
  --requiredActions: list # item shape: {alias?: string, config?: record, defaultAction?: bool, enabled?: bool, name?: string, priority?: int, providerId?: string}
  --resetCredentialsFlow: string
  --resetPasswordAllowed: oneof<nothing, bool>
  --revokeRefreshToken: oneof<nothing, bool>
  --roles: record # shape: {client?: record, realm?: list}
  --scopeMappings: list # item shape: {client?: string, clientScope?: string, roles?: list, self?: string}
  --smtpServer: record
  --sslRequired: string
  --ssoSessionIdleTimeout: int # format: int32
  --ssoSessionIdleTimeoutRememberMe: int # format: int32
  --ssoSessionMaxLifespan: int # format: int32
  --ssoSessionMaxLifespanRememberMe: int # format: int32
  --supportedLocales: list
  --userFederationMappers: list # item shape: {config?: record, federationMapperType?: string, federationProviderDisplayName?: string, id?: string, name?: string}
  --userFederationProviders: list # item shape: {changedSyncPeriod?: int, config?: record, displayName?: string, fullSyncPeriod?: int, id?: string, lastSync?: int, priority?: int, providerName?: string}
  --userManagedAccessAllowed: oneof<nothing, bool>
  --users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list, requiredActions?: list, self?: string, serviceAccountClientId?: string, username?: string}
  --verifyEmail: oneof<nothing, bool>
  --waitIncrementSeconds: int # format: int32
  --webAuthnPolicyAcceptableAaguids: list
  --webAuthnPolicyAttestationConveyancePreference: string
  --webAuthnPolicyAuthenticatorAttachment: string
  --webAuthnPolicyAvoidSameAuthenticatorRegister: oneof<nothing, bool>
  --webAuthnPolicyCreateTimeout: int # format: int32
  --webAuthnPolicyPasswordlessAcceptableAaguids: list
  --webAuthnPolicyPasswordlessAttestationConveyancePreference: string
  --webAuthnPolicyPasswordlessAuthenticatorAttachment: string
  --webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister: oneof<nothing, bool>
  --webAuthnPolicyPasswordlessCreateTimeout: int # format: int32
  --webAuthnPolicyPasswordlessRequireResidentKey: string
  --webAuthnPolicyPasswordlessRpEntityName: string
  --webAuthnPolicyPasswordlessRpId: string
  --webAuthnPolicyPasswordlessSignatureAlgorithms: list
  --webAuthnPolicyPasswordlessUserVerificationRequirement: string
  --webAuthnPolicyRequireResidentKey: string
  --webAuthnPolicyRpEntityName: string
  --webAuthnPolicyRpId: string
  --webAuthnPolicySignatureAlgorithms: list
  --webAuthnPolicyUserVerificationRequirement: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)")
  let body = {accessCodeLifespan: $accessCodeLifespan, accessCodeLifespanLogin: $accessCodeLifespanLogin, accessCodeLifespanUserAction: $accessCodeLifespanUserAction, accessTokenLifespan: $accessTokenLifespan, accessTokenLifespanForImplicitFlow: $accessTokenLifespanForImplicitFlow, accountTheme: $accountTheme, actionTokenGeneratedByAdminLifespan: $actionTokenGeneratedByAdminLifespan, actionTokenGeneratedByUserLifespan: $actionTokenGeneratedByUserLifespan, adminEventsDetailsEnabled: $adminEventsDetailsEnabled, adminEventsEnabled: $adminEventsEnabled, adminTheme: $adminTheme, attributes: $attributes, authenticationFlows: $authenticationFlows, authenticatorConfig: $authenticatorConfig, browserFlow: $browserFlow, browserSecurityHeaders: $browserSecurityHeaders, bruteForceProtected: $bruteForceProtected, clientAuthenticationFlow: $clientAuthenticationFlow, clientScopeMappings: $clientScopeMappings, clientScopes: $clientScopes, clientSessionIdleTimeout: $clientSessionIdleTimeout, clientSessionMaxLifespan: $clientSessionMaxLifespan, clients: $clients, components: $components, defaultDefaultClientScopes: $defaultDefaultClientScopes, defaultGroups: $defaultGroups, defaultLocale: $defaultLocale, defaultOptionalClientScopes: $defaultOptionalClientScopes, defaultRoles: $defaultRoles, defaultSignatureAlgorithm: $defaultSignatureAlgorithm, directGrantFlow: $directGrantFlow, displayName: $displayName, displayNameHtml: $displayNameHtml, dockerAuthenticationFlow: $dockerAuthenticationFlow, duplicateEmailsAllowed: $duplicateEmailsAllowed, editUsernameAllowed: $editUsernameAllowed, emailTheme: $emailTheme, enabled: $enabled, enabledEventTypes: $enabledEventTypes, eventsEnabled: $eventsEnabled, eventsExpiration: $eventsExpiration, eventsListeners: $eventsListeners, failureFactor: $failureFactor, federatedUsers: $federatedUsers, groups: $groups, id: $id, identityProviderMappers: $identityProviderMappers, identityProviders: $identityProviders, internationalizationEnabled: $internationalizationEnabled, keycloakVersion: $keycloakVersion, loginTheme: $loginTheme, loginWithEmailAllowed: $loginWithEmailAllowed, maxDeltaTimeSeconds: $maxDeltaTimeSeconds, maxFailureWaitSeconds: $maxFailureWaitSeconds, minimumQuickLoginWaitSeconds: $minimumQuickLoginWaitSeconds, notBefore: $notBefore, offlineSessionIdleTimeout: $offlineSessionIdleTimeout, offlineSessionMaxLifespan: $offlineSessionMaxLifespan, offlineSessionMaxLifespanEnabled: $offlineSessionMaxLifespanEnabled, otpPolicyAlgorithm: $otpPolicyAlgorithm, otpPolicyDigits: $otpPolicyDigits, otpPolicyInitialCounter: $otpPolicyInitialCounter, otpPolicyLookAheadWindow: $otpPolicyLookAheadWindow, otpPolicyPeriod: $otpPolicyPeriod, otpPolicyType: $otpPolicyType, otpSupportedApplications: $otpSupportedApplications, passwordPolicy: $passwordPolicy, permanentLockout: $permanentLockout, protocolMappers: $protocolMappers, quickLoginCheckMilliSeconds: $quickLoginCheckMilliSeconds, realm: $body_realm, refreshTokenMaxReuse: $refreshTokenMaxReuse, registrationAllowed: $registrationAllowed, registrationEmailAsUsername: $registrationEmailAsUsername, registrationFlow: $registrationFlow, rememberMe: $rememberMe, requiredActions: $requiredActions, resetCredentialsFlow: $resetCredentialsFlow, resetPasswordAllowed: $resetPasswordAllowed, revokeRefreshToken: $revokeRefreshToken, roles: $roles, scopeMappings: $scopeMappings, smtpServer: $smtpServer, sslRequired: $sslRequired, ssoSessionIdleTimeout: $ssoSessionIdleTimeout, ssoSessionIdleTimeoutRememberMe: $ssoSessionIdleTimeoutRememberMe, ssoSessionMaxLifespan: $ssoSessionMaxLifespan, ssoSessionMaxLifespanRememberMe: $ssoSessionMaxLifespanRememberMe, supportedLocales: $supportedLocales, userFederationMappers: $userFederationMappers, userFederationProviders: $userFederationProviders, userManagedAccessAllowed: $userManagedAccessAllowed, users: $users, verifyEmail: $verifyEmail, waitIncrementSeconds: $waitIncrementSeconds, webAuthnPolicyAcceptableAaguids: $webAuthnPolicyAcceptableAaguids, webAuthnPolicyAttestationConveyancePreference: $webAuthnPolicyAttestationConveyancePreference, webAuthnPolicyAuthenticatorAttachment: $webAuthnPolicyAuthenticatorAttachment, webAuthnPolicyAvoidSameAuthenticatorRegister: $webAuthnPolicyAvoidSameAuthenticatorRegister, webAuthnPolicyCreateTimeout: $webAuthnPolicyCreateTimeout, webAuthnPolicyPasswordlessAcceptableAaguids: $webAuthnPolicyPasswordlessAcceptableAaguids, webAuthnPolicyPasswordlessAttestationConveyancePreference: $webAuthnPolicyPasswordlessAttestationConveyancePreference, webAuthnPolicyPasswordlessAuthenticatorAttachment: $webAuthnPolicyPasswordlessAuthenticatorAttachment, webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister: $webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister, webAuthnPolicyPasswordlessCreateTimeout: $webAuthnPolicyPasswordlessCreateTimeout, webAuthnPolicyPasswordlessRequireResidentKey: $webAuthnPolicyPasswordlessRequireResidentKey, webAuthnPolicyPasswordlessRpEntityName: $webAuthnPolicyPasswordlessRpEntityName, webAuthnPolicyPasswordlessRpId: $webAuthnPolicyPasswordlessRpId, webAuthnPolicyPasswordlessSignatureAlgorithms: $webAuthnPolicyPasswordlessSignatureAlgorithms, webAuthnPolicyPasswordlessUserVerificationRequirement: $webAuthnPolicyPasswordlessUserVerificationRequirement, webAuthnPolicyRequireResidentKey: $webAuthnPolicyRequireResidentKey, webAuthnPolicyRpEntityName: $webAuthnPolicyRpEntityName, webAuthnPolicyRpId: $webAuthnPolicyRpId, webAuthnPolicySignatureAlgorithms: $webAuthnPolicySignatureAlgorithms, webAuthnPolicyUserVerificationRequirement: $webAuthnPolicyUserVerificationRequirement} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete all admin events
#
# DELETE /{realm}/admin-events
export def "admin-events delete" [
  realm: string
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
  let full_url = (build-url $base $"/($realm)/admin-events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get admin events   Returns all admin events, or filters events based on URL query parameters listed here
#
# GET /{realm}/admin-events
export def "admin-events get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authClient: string
  --authIpAddress: string
  --authRealm: string
  --authUser: string # user id
  --dateFrom: string
  --dateTo: string
  --first: int # format: int32
  --max: int # Maximum results size (defaults to 100) (format: int32)
  --operationTypes: list
  --resourcePath: string
  --resourceTypes: list
]: nothing -> table<authDetails: record<clientId: string, ipAddress: string, realmId: string, userId: string>, error: string, operationType: string, realmId: string, representation: string, resourcePath: string, resourceType: string, time: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "authClient" $authClient "scalar") (serialize-qp "authIpAddress" $authIpAddress "scalar") (serialize-qp "authRealm" $authRealm "scalar") (serialize-qp "authUser" $authUser "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "operationTypes" $operationTypes "multi") (serialize-qp "resourcePath" $resourcePath "scalar") (serialize-qp "resourceTypes" $resourceTypes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/admin-events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear any user login failures for all users   This can release temporary disabled users
#
# DELETE /{realm}/attack-detection/brute-force/users
export def "attack-detection-brute-force-users delete-by-realm" [
  realm: string
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
  let full_url = (build-url $base $"/($realm)/attack-detection/brute-force/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear any user login failures for the user   This can release temporary disabled user
#
# DELETE /{realm}/attack-detection/brute-force/users/{userId}
export def "attack-detection-brute-force-users delete-by-realm-userId" [
  realm: string
  userId: string
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
  let full_url = (build-url $base $"/($realm)/attack-detection/brute-force/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get status of a username in brute force detection
#
# GET /{realm}/attack-detection/brute-force/users/{userId}
export def "attack-detection-brute-force-users get" [
  realm: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/attack-detection/brute-force/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get authenticator providers   Returns a list of authenticator providers.
#
# GET /{realm}/authentication/authenticator-providers
export def "authentication-authenticator-providers get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/authenticator-providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get client authenticator providers   Returns a list of client authenticator providers.
#
# GET /{realm}/authentication/client-authenticator-providers
export def "authentication-client-authenticator-providers get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/client-authenticator-providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get authenticator provider’s configuration description
#
# GET /{realm}/authentication/config-description/{providerId}
export def "authentication-config-description get" [
  realm: string
  providerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<helpText: string, name: string, properties: table<defaultValue: record, helpText: string, label: string, name: string, options: list, secret: bool, type: string>, providerId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/config-description/($providerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete authenticator configuration
#
# DELETE /{realm}/authentication/config/{id}
export def "authentication-config delete" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/authentication/config/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get authenticator configuration
#
# GET /{realm}/authentication/config/{id}
export def "authentication-config get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alias: string, config: record, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/config/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update authenticator configuration
#
# PUT /{realm}/authentication/config/{id}
export def "authentication-config put" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --config: record
  --body-id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/config/($id)")
  let body = {alias: $alias, config: $config, id: $body_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add new authentication execution
#
# POST /{realm}/authentication/executions
export def "authentication-executions post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authenticator: string
  --authenticatorConfig: string
  --authenticatorFlow: oneof<nothing, bool>
  --autheticatorFlow: oneof<nothing, bool>
  --flowId: string
  --id: string
  --parentFlow: string
  --priority: int # format: int32
  --requirement: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/executions")
  let body = {authenticator: $authenticator, authenticatorConfig: $authenticatorConfig, authenticatorFlow: $authenticatorFlow, autheticatorFlow: $autheticatorFlow, flowId: $flowId, id: $id, parentFlow: $parentFlow, priority: $priority, requirement: $requirement} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete execution
#
# DELETE /{realm}/authentication/executions/{executionId}
export def "authentication-executions delete" [
  realm: string
  executionId: string
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
  let full_url = (build-url $base $"/($realm)/authentication/executions/($executionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Single Execution
#
# GET /{realm}/authentication/executions/{executionId}
export def "authentication-executions get" [
  realm: string
  executionId: string
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
  let full_url = (build-url $base $"/($realm)/authentication/executions/($executionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update execution with new configuration
#
# POST /{realm}/authentication/executions/{executionId}/config
export def "authentication-executions-config post" [
  realm: string
  executionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --config: record
  --id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/executions/($executionId)/config")
  let body = {alias: $alias, config: $config, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lower execution’s priority
#
# POST /{realm}/authentication/executions/{executionId}/lower-priority
export def "authentication-executions-lower-priority post" [
  realm: string
  executionId: string
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
  let full_url = (build-url $base $"/($realm)/authentication/executions/($executionId)/lower-priority")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Raise execution’s priority
#
# POST /{realm}/authentication/executions/{executionId}/raise-priority
export def "authentication-executions-raise-priority post" [
  realm: string
  executionId: string
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
  let full_url = (build-url $base $"/($realm)/authentication/executions/($executionId)/raise-priority")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get authentication flows   Returns a list of authentication flows.
#
# GET /{realm}/authentication/flows
export def "authentication-flows list" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<alias: string, authenticationExecutions: list<record>, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/flows")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new authentication flow
#
# POST /{realm}/authentication/flows
# --authenticationExecutions item shape: {authenticator?: string, authenticatorConfig?: string, authenticatorFlow?: bool, autheticatorFlow?: bool, flowAlias?: string, priority?: int, requirement?: string, userSetupAllowed?: bool}
export def "authentication-flows post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --authenticationExecutions: list # item shape: {authenticator?: string, authenticatorConfig?: string, authenticatorFlow?: bool, autheticatorFlow?: bool, flowAlias?: string, priority?: int, requirement?: string, userSetupAllowed?: bool}
  --builtIn: oneof<nothing, bool>
  --description: string
  --id: string
  --providerId: string
  --topLevel: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/flows")
  let body = {alias: $alias, authenticationExecutions: $authenticationExecutions, builtIn: $builtIn, description: $description, id: $id, providerId: $providerId, topLevel: $topLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Copy existing authentication flow under a new name   The new name is given as 'newName' attribute of the passed JSON object
#
# POST /{realm}/authentication/flows/{flowAlias}/copy
export def "authentication-flows-copy post" [
  realm: string
  flowAlias: string
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
  let full_url = (build-url $base $"/($realm)/authentication/flows/($flowAlias)/copy")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get authentication executions for a flow
#
# GET /{realm}/authentication/flows/{flowAlias}/executions
export def "authentication-flows-executions get" [
  realm: string
  flowAlias: string
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
  let full_url = (build-url $base $"/($realm)/authentication/flows/($flowAlias)/executions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update authentication executions of a flow
#
# PUT /{realm}/authentication/flows/{flowAlias}/executions
export def "authentication-flows-executions put" [
  realm: string
  flowAlias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --authenticationConfig: string
  --authenticationFlow: oneof<nothing, bool>
  --configurable: oneof<nothing, bool>
  --displayName: string
  --flowId: string
  --id: string
  --index: int # format: int32
  --level: int # format: int32
  --providerId: string
  --requirement: string
  --requirementChoices: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/flows/($flowAlias)/executions")
  let body = {alias: $alias, authenticationConfig: $authenticationConfig, authenticationFlow: $authenticationFlow, configurable: $configurable, displayName: $displayName, flowId: $flowId, id: $id, index: $index, level: $level, providerId: $providerId, requirement: $requirement, requirementChoices: $requirementChoices} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add new authentication execution to a flow
#
# POST /{realm}/authentication/flows/{flowAlias}/executions/execution
export def "authentication-flows-executions-execution post" [
  realm: string
  flowAlias: string
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
  let full_url = (build-url $base $"/($realm)/authentication/flows/($flowAlias)/executions/execution")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add new flow with new execution to existing flow
#
# POST /{realm}/authentication/flows/{flowAlias}/executions/flow
export def "authentication-flows-executions-flow post" [
  realm: string
  flowAlias: string
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
  let full_url = (build-url $base $"/($realm)/authentication/flows/($flowAlias)/executions/flow")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an authentication flow
#
# DELETE /{realm}/authentication/flows/{id}
export def "authentication-flows delete" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/authentication/flows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get authentication flow for id
#
# GET /{realm}/authentication/flows/{id}
export def "authentication-flows get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alias: string, authenticationExecutions: table<authenticator: string, authenticatorConfig: string, authenticatorFlow: bool, autheticatorFlow: bool, flowAlias: string, priority: int, requirement: string, userSetupAllowed: bool>, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/flows/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an authentication flow
#
# PUT /{realm}/authentication/flows/{id}
# --authenticationExecutions item shape: {authenticator?: string, authenticatorConfig?: string, authenticatorFlow?: bool, autheticatorFlow?: bool, flowAlias?: string, priority?: int, requirement?: string, userSetupAllowed?: bool}
export def "authentication-flows put" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --authenticationExecutions: list # item shape: {authenticator?: string, authenticatorConfig?: string, authenticatorFlow?: bool, autheticatorFlow?: bool, flowAlias?: string, priority?: int, requirement?: string, userSetupAllowed?: bool}
  --builtIn: oneof<nothing, bool>
  --description: string
  --body-id: string
  --providerId: string
  --topLevel: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/flows/($id)")
  let body = {alias: $alias, authenticationExecutions: $authenticationExecutions, builtIn: $builtIn, description: $description, id: $body_id, providerId: $providerId, topLevel: $topLevel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get form action providers   Returns a list of form action providers.
#
# GET /{realm}/authentication/form-action-providers
export def "authentication-form-action-providers get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/form-action-providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get form providers   Returns a list of form providers.
#
# GET /{realm}/authentication/form-providers
export def "authentication-form-providers get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/form-providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get configuration descriptions for all clients
#
# GET /{realm}/authentication/per-client-config-description
export def "authentication-per-client-config-description get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/per-client-config-description")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register a new required actions
#
# POST /{realm}/authentication/register-required-action
export def "authentication-register-required-action post" [
  realm: string
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
  let full_url = (build-url $base $"/($realm)/authentication/register-required-action")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get required actions   Returns a list of required actions.
#
# GET /{realm}/authentication/required-actions
export def "authentication-required-actions list" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/required-actions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete required action
#
# DELETE /{realm}/authentication/required-actions/{alias}
export def "authentication-required-actions delete" [
  realm: string
  alias: string
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
  let full_url = (build-url $base $"/($realm)/authentication/required-actions/($alias)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get required action for alias
#
# GET /{realm}/authentication/required-actions/{alias}
export def "authentication-required-actions get" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/required-actions/($alias)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update required action
#
# PUT /{realm}/authentication/required-actions/{alias}
export def "authentication-required-actions put" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-alias: string
  --config: record
  --defaultAction: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --name: string
  --priority: int # format: int32
  --providerId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/required-actions/($alias)")
  let body = {alias: $body_alias, config: $config, defaultAction: $defaultAction, enabled: $enabled, name: $name, priority: $priority, providerId: $providerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lower required action’s priority
#
# POST /{realm}/authentication/required-actions/{alias}/lower-priority
export def "authentication-required-actions-lower-priority post" [
  realm: string
  alias: string
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
  let full_url = (build-url $base $"/($realm)/authentication/required-actions/($alias)/lower-priority")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Raise required action’s priority
#
# POST /{realm}/authentication/required-actions/{alias}/raise-priority
export def "authentication-required-actions-raise-priority post" [
  realm: string
  alias: string
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
  let full_url = (build-url $base $"/($realm)/authentication/required-actions/($alias)/raise-priority")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get unregistered required actions   Returns a list of unregistered required actions.
#
# GET /{realm}/authentication/unregistered-required-actions
export def "authentication-unregistered-required-actions get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/authentication/unregistered-required-actions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear cache of external public keys (Public keys of clients or Identity providers)
#
# POST /{realm}/clear-keys-cache
export def "clear-keys-cache post" [
  realm: string
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
  let full_url = (build-url $base $"/($realm)/clear-keys-cache")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear realm cache
#
# POST /{realm}/clear-realm-cache
export def "clear-realm-cache post" [
  realm: string
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
  let full_url = (build-url $base $"/($realm)/clear-realm-cache")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear user cache
#
# POST /{realm}/clear-user-cache
export def "clear-user-cache post" [
  realm: string
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
  let full_url = (build-url $base $"/($realm)/clear-user-cache")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Base path for importing clients under this realm.
#
# POST /{realm}/client-description-converter
export def "client-description-converter post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list<record>, policyEnforcementMode: string, resources: list<record>, scopes: list<record>>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-description-converter")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Base path for retrieve providers with the configProperties properly filled
#
# GET /{realm}/client-registration-policy/providers
export def "client-registration-policy-providers get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<helpText: string, id: string, metadata: record, properties: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-registration-policy/providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get client scopes belonging to the realm   Returns a list of client scopes belonging to the realm
#
# GET /{realm}/client-scopes
export def "client-scopes list" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new client scope   Client Scope’s name must be unique!
#
# POST /{realm}/client-scopes
# --protocolMappers item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
export def "client-scopes post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --description: string
  --id: string
  --name: string
  --protocol: string
  --protocolMappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes")
  let body = {attributes: $attributes, description: $description, id: $id, name: $name, protocol: $protocol, protocolMappers: $protocolMappers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the mapper
#
# DELETE /{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}
export def "client-scopes-protocol-mappers-models delete" [
  realm: string
  id1: string
  id2: string
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
  let full_url = (build-url $base $"/($realm)/client-scopes/($id1)/protocol-mappers/models/($id2)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get mapper by id
#
# GET /{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}
export def "client-scopes-protocol-mappers-models get" [
  realm: string
  id1: string
  id2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config: record, id: string, name: string, protocol: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id1)/protocol-mappers/models/($id2)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the mapper
#
# PUT /{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}
export def "client-scopes-protocol-mappers-models put" [
  realm: string
  id1: string
  id2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --id: string
  --name: string
  --protocol: string
  --protocolMapper: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id1)/protocol-mappers/models/($id2)")
  let body = {config: $config, id: $id, name: $name, protocol: $protocol, protocolMapper: $protocolMapper} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the client scope
#
# DELETE /{realm}/client-scopes/{id}
export def "client-scopes delete" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get representation of the client scope
#
# GET /{realm}/client-scopes/{id}
export def "client-scopes get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the client scope
#
# PUT /{realm}/client-scopes/{id}
# --protocolMappers item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
export def "client-scopes put" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --description: string
  --body-id: string
  --name: string
  --protocol: string
  --protocolMappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)")
  let body = {attributes: $attributes, description: $description, id: $body_id, name: $name, protocol: $protocol, protocolMappers: $protocolMappers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create multiple mappers
#
# POST /{realm}/client-scopes/{id}/protocol-mappers/add-models
export def "client-scopes-protocol-mappers-add-models post" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/protocol-mappers/add-models")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get mappers
#
# GET /{realm}/client-scopes/{id}/protocol-mappers/models
export def "client-scopes-protocol-mappers-models list" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<config: record, id: string, name: string, protocol: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/protocol-mappers/models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a mapper
#
# POST /{realm}/client-scopes/{id}/protocol-mappers/models
export def "client-scopes-protocol-mappers-models post" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --body-id: string
  --name: string
  --protocol: string
  --protocolMapper: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/protocol-mappers/models")
  let body = {config: $config, id: $body_id, name: $name, protocol: $protocol, protocolMapper: $protocolMapper} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get mappers by name for a specific protocol
#
# GET /{realm}/client-scopes/{id}/protocol-mappers/protocol/{protocol}
export def "client-scopes-protocol-mappers-protocol get" [
  realm: string
  id: string
  protocol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<config: record, id: string, name: string, protocol: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/protocol-mappers/protocol/($protocol)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all scope mappings for the client
#
# GET /{realm}/client-scopes/{id}/scope-mappings
export def "client-scopes-scope-mappings get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/scope-mappings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove client-level roles from the client’s scope.
#
# DELETE /{realm}/client-scopes/{id}/scope-mappings/clients/{client}
export def "client-scopes-scope-mappings-clients delete" [
  realm: string
  id: string
  client: string
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
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/scope-mappings/clients/($client)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the roles associated with a client’s scope   Returns roles for the client.
#
# GET /{realm}/client-scopes/{id}/scope-mappings/clients/{client}
export def "client-scopes-scope-mappings-clients get" [
  realm: string
  id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/scope-mappings/clients/($client)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add client-level roles to the client’s scope
#
# POST /{realm}/client-scopes/{id}/scope-mappings/clients/{client}
export def "client-scopes-scope-mappings-clients post" [
  realm: string
  id: string
  client: string
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
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/scope-mappings/clients/($client)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# The available client-level roles   Returns the roles for the client that can be associated with the client’s scope
#
# GET /{realm}/client-scopes/{id}/scope-mappings/clients/{client}/available
export def "client-scopes-scope-mappings-clients-available get" [
  realm: string
  id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/scope-mappings/clients/($client)/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get effective client roles   Returns the roles for the client that are associated with the client’s scope.
#
# GET /{realm}/client-scopes/{id}/scope-mappings/clients/{client}/composite
export def "client-scopes-scope-mappings-clients-composite get" [
  realm: string
  id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/scope-mappings/clients/($client)/composite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a set of realm-level roles from the client’s scope
#
# DELETE /{realm}/client-scopes/{id}/scope-mappings/realm
export def "client-scopes-scope-mappings-realm delete" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/scope-mappings/realm")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get realm-level roles associated with the client’s scope
#
# GET /{realm}/client-scopes/{id}/scope-mappings/realm
export def "client-scopes-scope-mappings-realm get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/scope-mappings/realm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a set of realm-level roles to the client’s scope
#
# POST /{realm}/client-scopes/{id}/scope-mappings/realm
export def "client-scopes-scope-mappings-realm post" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/scope-mappings/realm")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get realm-level roles that are available to attach to this client’s scope
#
# GET /{realm}/client-scopes/{id}/scope-mappings/realm/available
export def "client-scopes-scope-mappings-realm-available get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/scope-mappings/realm/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get effective realm-level roles associated with the client’s scope   What this does is recurse  any composite roles associated with the client’s scope and adds the roles to this lists.
#
# GET /{realm}/client-scopes/{id}/scope-mappings/realm/composite
export def "client-scopes-scope-mappings-realm-composite get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-scopes/($id)/scope-mappings/realm/composite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get client session stats   Returns a JSON map.
#
# GET /{realm}/client-session-stats
export def "client-session-stats get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/client-session-stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get clients belonging to the realm   Returns a list of clients belonging to the realm
#
# GET /{realm}/clients
export def "clients list" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clientId: string # filter by clientId
  --first: int # the first result (format: int32)
  --max: int # the max results to return (format: int32)
  --search: oneof<nothing, bool> # whether this is a search query or a getClientById query
  --viewableOnly: oneof<nothing, bool> # filter clients that cannot be viewed in full by admin
]: nothing -> table<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list, policyEnforcementMode: string, resources: list, scopes: list>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: list<record>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $clientId "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "viewableOnly" $viewableOnly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new client   Client’s client_id must be unique!
#
# POST /{realm}/clients
# --authorizationSettings shape: {allowRemoteResourceManagement?: bool, clientId?: string, decisionStrategy?: "AFFIRMATIVE"|"UNANIMOUS"|"CONSENSUS", id?: string, name?: string, policies?: list, policyEnforcementMode?: "ENFORCING"|"PERMISSIVE"|"DISABLED", resources?: list, scopes?: list}
# --protocolMappers item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
export def "clients post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --adminUrl: string
  --alwaysDisplayInConsole: oneof<nothing, bool>
  --attributes: record
  --authenticationFlowBindingOverrides: record
  --authorizationServicesEnabled: oneof<nothing, bool>
  --authorizationSettings: record # shape: {allowRemoteResourceManagement?: bool, clientId?: string, decisionStrategy?: "AFFIRMATIVE"|"UNANIMOUS"|"CONSENSUS", id?: string, name?: string, policies?: list, policyEnforcementMode?: "ENFORCING"|"PERMISSIVE"|"DISABLED", resources?: list, scopes?: list}
  --baseUrl: string
  --bearerOnly: oneof<nothing, bool>
  --clientAuthenticatorType: string
  --clientId: string
  --consentRequired: oneof<nothing, bool>
  --defaultClientScopes: list
  --defaultRoles: list
  --description: string
  --directAccessGrantsEnabled: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --frontchannelLogout: oneof<nothing, bool>
  --fullScopeAllowed: oneof<nothing, bool>
  --id: string
  --implicitFlowEnabled: oneof<nothing, bool>
  --name: string
  --nodeReRegistrationTimeout: int # format: int32
  --notBefore: int # format: int32
  --optionalClientScopes: list
  --origin: string
  --protocol: string
  --protocolMappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
  --publicClient: oneof<nothing, bool>
  --redirectUris: list
  --registeredNodes: record
  --registrationAccessToken: string
  --rootUrl: string
  --secret: string
  --serviceAccountsEnabled: oneof<nothing, bool>
  --standardFlowEnabled: oneof<nothing, bool>
  --surrogateAuthRequired: oneof<nothing, bool>
  --webOrigins: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients")
  let body = {access: $access, adminUrl: $adminUrl, alwaysDisplayInConsole: $alwaysDisplayInConsole, attributes: $attributes, authenticationFlowBindingOverrides: $authenticationFlowBindingOverrides, authorizationServicesEnabled: $authorizationServicesEnabled, authorizationSettings: $authorizationSettings, baseUrl: $baseUrl, bearerOnly: $bearerOnly, clientAuthenticatorType: $clientAuthenticatorType, clientId: $clientId, consentRequired: $consentRequired, defaultClientScopes: $defaultClientScopes, defaultRoles: $defaultRoles, description: $description, directAccessGrantsEnabled: $directAccessGrantsEnabled, enabled: $enabled, frontchannelLogout: $frontchannelLogout, fullScopeAllowed: $fullScopeAllowed, id: $id, implicitFlowEnabled: $implicitFlowEnabled, name: $name, nodeReRegistrationTimeout: $nodeReRegistrationTimeout, notBefore: $notBefore, optionalClientScopes: $optionalClientScopes, origin: $origin, protocol: $protocol, protocolMappers: $protocolMappers, publicClient: $publicClient, redirectUris: $redirectUris, registeredNodes: $registeredNodes, registrationAccessToken: $registrationAccessToken, rootUrl: $rootUrl, secret: $secret, serviceAccountsEnabled: $serviceAccountsEnabled, standardFlowEnabled: $standardFlowEnabled, surrogateAuthRequired: $surrogateAuthRequired, webOrigins: $webOrigins} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /{realm}/clients-initial-access
export def "clients-initial-access get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<count: int, expiration: int, id: string, remainingCount: int, timestamp: int, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients-initial-access")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new initial access token.
#
# POST /{realm}/clients-initial-access
export def "clients-initial-access post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # format: int32
  --expiration: int # format: int32
]: any -> record<count: int, expiration: int, id: string, remainingCount: int, timestamp: int, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients-initial-access")
  let body = {count: $count, expiration: $expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /{realm}/clients-initial-access/{id}
export def "clients-initial-access delete" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/clients-initial-access/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the mapper
#
# DELETE /{realm}/clients/{id1}/protocol-mappers/models/{id2}
export def "clients-protocol-mappers-models delete" [
  realm: string
  id1: string
  id2: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id1)/protocol-mappers/models/($id2)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get mapper by id
#
# GET /{realm}/clients/{id1}/protocol-mappers/models/{id2}
export def "clients-protocol-mappers-models get" [
  realm: string
  id1: string
  id2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config: record, id: string, name: string, protocol: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id1)/protocol-mappers/models/($id2)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the mapper
#
# PUT /{realm}/clients/{id1}/protocol-mappers/models/{id2}
export def "clients-protocol-mappers-models put" [
  realm: string
  id1: string
  id2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --id: string
  --name: string
  --protocol: string
  --protocolMapper: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id1)/protocol-mappers/models/($id2)")
  let body = {config: $config, id: $id, name: $name, protocol: $protocol, protocolMapper: $protocolMapper} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the client
#
# DELETE /{realm}/clients/{id}
export def "clients delete" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get representation of the client
#
# GET /{realm}/clients/{id}
export def "clients get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list<record>, policyEnforcementMode: string, resources: list<record>, scopes: list<record>>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the client
#
# PUT /{realm}/clients/{id}
# --authorizationSettings shape: {allowRemoteResourceManagement?: bool, clientId?: string, decisionStrategy?: "AFFIRMATIVE"|"UNANIMOUS"|"CONSENSUS", id?: string, name?: string, policies?: list, policyEnforcementMode?: "ENFORCING"|"PERMISSIVE"|"DISABLED", resources?: list, scopes?: list}
# --protocolMappers item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
export def "clients put" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --adminUrl: string
  --alwaysDisplayInConsole: oneof<nothing, bool>
  --attributes: record
  --authenticationFlowBindingOverrides: record
  --authorizationServicesEnabled: oneof<nothing, bool>
  --authorizationSettings: record # shape: {allowRemoteResourceManagement?: bool, clientId?: string, decisionStrategy?: "AFFIRMATIVE"|"UNANIMOUS"|"CONSENSUS", id?: string, name?: string, policies?: list, policyEnforcementMode?: "ENFORCING"|"PERMISSIVE"|"DISABLED", resources?: list, scopes?: list}
  --baseUrl: string
  --bearerOnly: oneof<nothing, bool>
  --clientAuthenticatorType: string
  --clientId: string
  --consentRequired: oneof<nothing, bool>
  --defaultClientScopes: list
  --defaultRoles: list
  --description: string
  --directAccessGrantsEnabled: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --frontchannelLogout: oneof<nothing, bool>
  --fullScopeAllowed: oneof<nothing, bool>
  --body-id: string
  --implicitFlowEnabled: oneof<nothing, bool>
  --name: string
  --nodeReRegistrationTimeout: int # format: int32
  --notBefore: int # format: int32
  --optionalClientScopes: list
  --origin: string
  --protocol: string
  --protocolMappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
  --publicClient: oneof<nothing, bool>
  --redirectUris: list
  --registeredNodes: record
  --registrationAccessToken: string
  --rootUrl: string
  --secret: string
  --serviceAccountsEnabled: oneof<nothing, bool>
  --standardFlowEnabled: oneof<nothing, bool>
  --surrogateAuthRequired: oneof<nothing, bool>
  --webOrigins: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)")
  let body = {access: $access, adminUrl: $adminUrl, alwaysDisplayInConsole: $alwaysDisplayInConsole, attributes: $attributes, authenticationFlowBindingOverrides: $authenticationFlowBindingOverrides, authorizationServicesEnabled: $authorizationServicesEnabled, authorizationSettings: $authorizationSettings, baseUrl: $baseUrl, bearerOnly: $bearerOnly, clientAuthenticatorType: $clientAuthenticatorType, clientId: $clientId, consentRequired: $consentRequired, defaultClientScopes: $defaultClientScopes, defaultRoles: $defaultRoles, description: $description, directAccessGrantsEnabled: $directAccessGrantsEnabled, enabled: $enabled, frontchannelLogout: $frontchannelLogout, fullScopeAllowed: $fullScopeAllowed, id: $body_id, implicitFlowEnabled: $implicitFlowEnabled, name: $name, nodeReRegistrationTimeout: $nodeReRegistrationTimeout, notBefore: $notBefore, optionalClientScopes: $optionalClientScopes, origin: $origin, protocol: $protocol, protocolMappers: $protocolMappers, publicClient: $publicClient, redirectUris: $redirectUris, registeredNodes: $registeredNodes, registrationAccessToken: $registrationAccessToken, rootUrl: $rootUrl, secret: $secret, serviceAccountsEnabled: $serviceAccountsEnabled, standardFlowEnabled: $standardFlowEnabled, surrogateAuthRequired: $surrogateAuthRequired, webOrigins: $webOrigins} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get key info
#
# GET /{realm}/clients/{id}/certificates/{attr}
export def "clients-certificates get" [
  realm: string
  id: string
  attr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificate: string, kid: string, privateKey: string, publicKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/certificates/($attr)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a keystore file for the client, containing private key and public certificate
#
# POST /{realm}/clients/{id}/certificates/{attr}/download
export def "clients-certificates-download post" [
  realm: string
  id: string
  attr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string
  --keyAlias: string
  --keyPassword: string
  --realmAlias: string
  --realmCertificate: oneof<nothing, bool>
  --storePassword: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/certificates/($attr)/download")
  let body = {format: $format, keyAlias: $keyAlias, keyPassword: $keyPassword, realmAlias: $realmAlias, realmCertificate: $realmCertificate, storePassword: $storePassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate a new certificate with new key pair
#
# POST /{realm}/clients/{id}/certificates/{attr}/generate
export def "clients-certificates-generate post" [
  realm: string
  id: string
  attr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificate: string, kid: string, privateKey: string, publicKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/certificates/($attr)/generate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a new keypair and certificate, and get the private key file   Generates a keypair and certificate and serves the private key in a specified keystore format.
#
# POST /{realm}/clients/{id}/certificates/{attr}/generate-and-download
export def "clients-certificates-generate-and-download post" [
  realm: string
  id: string
  attr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string
  --keyAlias: string
  --keyPassword: string
  --realmAlias: string
  --realmCertificate: oneof<nothing, bool>
  --storePassword: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/certificates/($attr)/generate-and-download")
  let body = {format: $format, keyAlias: $keyAlias, keyPassword: $keyPassword, realmAlias: $realmAlias, realmCertificate: $realmCertificate, storePassword: $storePassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload certificate and eventually private key
#
# POST /{realm}/clients/{id}/certificates/{attr}/upload
export def "clients-certificates-upload post" [
  realm: string
  id: string
  attr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificate: string, kid: string, privateKey: string, publicKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/certificates/($attr)/upload")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload only certificate, not private key
#
# POST /{realm}/clients/{id}/certificates/{attr}/upload-certificate
export def "clients-certificates-upload-certificate post" [
  realm: string
  id: string
  attr: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificate: string, kid: string, privateKey: string, publicKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/certificates/($attr)/upload-certificate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the client secret
#
# GET /{realm}/clients/{id}/client-secret
export def "clients-client-secret get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/client-secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a new secret for the client
#
# POST /{realm}/clients/{id}/client-secret
export def "clients-client-secret post" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/client-secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get default client scopes.
#
# GET /{realm}/clients/{id}/default-client-scopes
export def "clients-default-client-scopes get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/default-client-scopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /{realm}/clients/{id}/default-client-scopes/{clientScopeId}
export def "clients-default-client-scopes delete" [
  realm: string
  id: string
  clientScopeId: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/default-client-scopes/($clientScopeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /{realm}/clients/{id}/default-client-scopes/{clientScopeId}
export def "clients-default-client-scopes put" [
  realm: string
  id: string
  clientScopeId: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/default-client-scopes/($clientScopeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create JSON with payload of example access token
#
# GET /{realm}/clients/{id}/evaluate-scopes/generate-example-access-token
export def "clients-evaluate-scopes-generate-example-access-token get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
  --userId: string
]: nothing -> record<acr: string, address: record<country: string, formatted: string, locality: string, postal_code: string, region: string, street_address: string>, allowed_origins: list<string>, at_hash: string, auth_time: int, authorization: record<permissions: list<record>>, azp: string, birthdate: string, c_hash: string, category: string, claims_locales: string, cnf: record<x5t_S256: string>, email: string, email_verified: bool, exp: int, family_name: string, gender: string, given_name: string, iat: int, iss: string, jti: string, locale: string, middle_name: string, name: string, nbf: int, nickname: string, nonce: string, otherClaims: record, phone_number: string, phone_number_verified: bool, picture: string, preferred_username: string, profile: string, realm_access: record<roles: list<string>, verify_caller: bool>, s_hash: string, scope: string, session_state: string, sub: string, trusted_certs: list<string>, typ: string, updated_at: int, website: string, zoneinfo: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/clients/($id)/evaluate-scopes/generate-example-access-token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return list of all protocol mappers, which will be used when generating tokens issued for particular client.
#
# GET /{realm}/clients/{id}/evaluate-scopes/protocol-mappers
export def "clients-evaluate-scopes-protocol-mappers get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
]: nothing -> table<containerId: string, containerName: string, containerType: string, mapperId: string, mapperName: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/clients/($id)/evaluate-scopes/protocol-mappers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get effective scope mapping of all roles of particular role container, which this client is defacto allowed to have in the accessToken issued for him.
#
# GET /{realm}/clients/{id}/evaluate-scopes/scope-mappings/{roleContainerId}/granted
export def "clients-evaluate-scopes-scope-mappings-granted get" [
  realm: string
  id: string
  roleContainerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/clients/($id)/evaluate-scopes/scope-mappings/($roleContainerId)/granted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get roles, which this client doesn’t have scope for and can’t have them in the accessToken issued for him.
#
# GET /{realm}/clients/{id}/evaluate-scopes/scope-mappings/{roleContainerId}/not-granted
export def "clients-evaluate-scopes-scope-mappings-not-granted get" [
  realm: string
  id: string
  roleContainerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/clients/($id)/evaluate-scopes/scope-mappings/($roleContainerId)/not-granted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{realm}/clients/{id}/installation/providers/{providerId}
export def "clients-installation-providers get" [
  realm: string
  id: string
  providerId: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/installation/providers/($providerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# GET /{realm}/clients/{id}/management/permissions
export def "clients-management-permissions get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/management/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# PUT /{realm}/clients/{id}/management/permissions
export def "clients-management-permissions put" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scopePermissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/management/permissions")
  let body = {enabled: $enabled, resource: $resource, scopePermissions: $scopePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Register a cluster node with the client   Manually register cluster node to this client - usually it’s not needed to call this directly as adapter should handle  by sending registration request to Keycloak
#
# POST /{realm}/clients/{id}/nodes
export def "clients-nodes post" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/nodes")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unregister a cluster node from the client
#
# DELETE /{realm}/clients/{id}/nodes/{node}
export def "clients-nodes delete" [
  realm: string
  id: string
  node: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/nodes/($node)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get application offline session count   Returns a number of offline user sessions associated with this client   {      "count": number  }
#
# GET /{realm}/clients/{id}/offline-session-count
export def "clients-offline-session-count get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/offline-session-count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get offline sessions for client   Returns a list of offline user sessions associated with this client
#
# GET /{realm}/clients/{id}/offline-sessions
export def "clients-offline-sessions get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first: int # Paging offset (format: int32)
  --max: int # Maximum results size (defaults to 100) (format: int32)
]: nothing -> table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/clients/($id)/offline-sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get optional client scopes.
#
# GET /{realm}/clients/{id}/optional-client-scopes
export def "clients-optional-client-scopes get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/optional-client-scopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /{realm}/clients/{id}/optional-client-scopes/{clientScopeId}
export def "clients-optional-client-scopes delete" [
  realm: string
  id: string
  clientScopeId: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/optional-client-scopes/($clientScopeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /{realm}/clients/{id}/optional-client-scopes/{clientScopeId}
export def "clients-optional-client-scopes put" [
  realm: string
  id: string
  clientScopeId: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/optional-client-scopes/($clientScopeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create multiple mappers
#
# POST /{realm}/clients/{id}/protocol-mappers/add-models
export def "clients-protocol-mappers-add-models post" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/protocol-mappers/add-models")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get mappers
#
# GET /{realm}/clients/{id}/protocol-mappers/models
export def "clients-protocol-mappers-models list" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<config: record, id: string, name: string, protocol: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/protocol-mappers/models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a mapper
#
# POST /{realm}/clients/{id}/protocol-mappers/models
export def "clients-protocol-mappers-models post" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --body-id: string
  --name: string
  --protocol: string
  --protocolMapper: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/protocol-mappers/models")
  let body = {config: $config, id: $body_id, name: $name, protocol: $protocol, protocolMapper: $protocolMapper} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get mappers by name for a specific protocol
#
# GET /{realm}/clients/{id}/protocol-mappers/protocol/{protocol}
export def "clients-protocol-mappers-protocol get" [
  realm: string
  id: string
  protocol: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<config: record, id: string, name: string, protocol: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/protocol-mappers/protocol/($protocol)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Push the client’s revocation policy to its admin URL   If the client has an admin URL, push revocation policy to it.
#
# POST /{realm}/clients/{id}/push-revocation
export def "clients-push-revocation post" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<failedRequests: list<string>, successRequests: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/push-revocation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a new registration access token for the client
#
# POST /{realm}/clients/{id}/registration-access-token
export def "clients-registration-access-token post" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list<record>, policyEnforcementMode: string, resources: list<record>, scopes: list<record>>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/registration-access-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all roles for the realm or client
#
# GET /{realm}/clients/{id}/roles
export def "clients-roles list" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --briefRepresentation: oneof<nothing, bool>
  --first: int # format: int32
  --max: int # format: int32
  --search: string
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "briefRepresentation" $briefRepresentation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new role for the realm or client
#
# POST /{realm}/clients/{id}/roles
# --composites shape: {client?: record, realm?: list}
export def "clients-roles post" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --clientRole: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list}
  --containerId: string
  --description: string
  --body-id: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles")
  let body = {attributes: $attributes, clientRole: $clientRole, composite: $composite, composites: $composites, containerId: $containerId, description: $description, id: $body_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role by name
#
# DELETE /{realm}/clients/{id}/roles/{role-name}
export def "clients-roles delete" [
  realm: string
  id: string
  role_name: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles/($role_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a role by name
#
# GET /{realm}/clients/{id}/roles/{role-name}
export def "clients-roles get" [
  realm: string
  id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list<string>>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles/($role_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role by name
#
# PUT /{realm}/clients/{id}/roles/{role-name}
# --composites shape: {client?: record, realm?: list}
export def "clients-roles put" [
  realm: string
  id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --clientRole: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list}
  --containerId: string
  --description: string
  --body-id: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles/($role_name)")
  let body = {attributes: $attributes, clientRole: $clientRole, composite: $composite, composites: $composites, containerId: $containerId, description: $description, id: $body_id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove roles from the role’s composite
#
# DELETE /{realm}/clients/{id}/roles/{role-name}/composites
export def "clients-roles-composites delete" [
  realm: string
  id: string
  role_name: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles/($role_name)/composites")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get composites of the role
#
# GET /{realm}/clients/{id}/roles/{role-name}/composites
export def "clients-roles-composites get" [
  realm: string
  id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles/($role_name)/composites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a composite to the role
#
# POST /{realm}/clients/{id}/roles/{role-name}/composites
export def "clients-roles-composites post" [
  realm: string
  id: string
  role_name: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles/($role_name)/composites")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# An app-level roles for the specified app for the role’s composite
#
# GET /{realm}/clients/{id}/roles/{role-name}/composites/clients/{client}
export def "clients-roles-composites-clients get" [
  realm: string
  id: string
  role_name: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles/($role_name)/composites/clients/($client)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get realm-level roles of the role’s composite
#
# GET /{realm}/clients/{id}/roles/{role-name}/composites/realm
export def "clients-roles-composites-realm get" [
  realm: string
  id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles/($role_name)/composites/realm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return List of Groups that have the specified role name
#
# GET /{realm}/clients/{id}/roles/{role-name}/groups
export def "clients-roles-groups get" [
  realm: string
  id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --briefRepresentation: oneof<nothing, bool> # if false, return a full representation of the GroupRepresentation objects
  --first: int # format: int32
  --max: int # format: int32
]: nothing -> table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "briefRepresentation" $briefRepresentation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles/($role_name)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# GET /{realm}/clients/{id}/roles/{role-name}/management/permissions
export def "clients-roles-management-permissions get" [
  realm: string
  id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles/($role_name)/management/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# PUT /{realm}/clients/{id}/roles/{role-name}/management/permissions
export def "clients-roles-management-permissions put" [
  realm: string
  id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scopePermissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles/($role_name)/management/permissions")
  let body = {enabled: $enabled, resource: $resource, scopePermissions: $scopePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return List of Users that have the specified role name
#
# GET /{realm}/clients/{id}/roles/{role-name}/users
export def "clients-roles-users get" [
  realm: string
  id: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first: int # format: int32
  --max: int # format: int32
]: nothing -> table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/clients/($id)/roles/($role_name)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all scope mappings for the client
#
# GET /{realm}/clients/{id}/scope-mappings
export def "clients-scope-mappings get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/scope-mappings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove client-level roles from the client’s scope.
#
# DELETE /{realm}/clients/{id}/scope-mappings/clients/{client}
export def "clients-scope-mappings-clients delete" [
  realm: string
  id: string
  client: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/scope-mappings/clients/($client)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the roles associated with a client’s scope   Returns roles for the client.
#
# GET /{realm}/clients/{id}/scope-mappings/clients/{client}
export def "clients-scope-mappings-clients get" [
  realm: string
  id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/scope-mappings/clients/($client)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add client-level roles to the client’s scope
#
# POST /{realm}/clients/{id}/scope-mappings/clients/{client}
export def "clients-scope-mappings-clients post" [
  realm: string
  id: string
  client: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/scope-mappings/clients/($client)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# The available client-level roles   Returns the roles for the client that can be associated with the client’s scope
#
# GET /{realm}/clients/{id}/scope-mappings/clients/{client}/available
export def "clients-scope-mappings-clients-available get" [
  realm: string
  id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/scope-mappings/clients/($client)/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get effective client roles   Returns the roles for the client that are associated with the client’s scope.
#
# GET /{realm}/clients/{id}/scope-mappings/clients/{client}/composite
export def "clients-scope-mappings-clients-composite get" [
  realm: string
  id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/scope-mappings/clients/($client)/composite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a set of realm-level roles from the client’s scope
#
# DELETE /{realm}/clients/{id}/scope-mappings/realm
export def "clients-scope-mappings-realm delete" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/scope-mappings/realm")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get realm-level roles associated with the client’s scope
#
# GET /{realm}/clients/{id}/scope-mappings/realm
export def "clients-scope-mappings-realm get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/scope-mappings/realm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a set of realm-level roles to the client’s scope
#
# POST /{realm}/clients/{id}/scope-mappings/realm
export def "clients-scope-mappings-realm post" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/clients/($id)/scope-mappings/realm")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get realm-level roles that are available to attach to this client’s scope
#
# GET /{realm}/clients/{id}/scope-mappings/realm/available
export def "clients-scope-mappings-realm-available get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/scope-mappings/realm/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get effective realm-level roles associated with the client’s scope   What this does is recurse  any composite roles associated with the client’s scope and adds the roles to this lists.
#
# GET /{realm}/clients/{id}/scope-mappings/realm/composite
export def "clients-scope-mappings-realm-composite get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/scope-mappings/realm/composite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user dedicated to the service account
#
# GET /{realm}/clients/{id}/service-account-user
export def "clients-service-account-user get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access: record, attributes: record, clientConsents: table<clientId: string, createdDate: int, grantedClientScopes: list, lastUpdatedDate: int>, clientRoles: record, createdTimestamp: int, credentials: table<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: table<identityProvider: string, userId: string, userName: string>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/service-account-user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get application session count   Returns a number of user sessions associated with this client   {      "count": number  }
#
# GET /{realm}/clients/{id}/session-count
export def "clients-session-count get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/session-count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test if registered cluster nodes are available   Tests availability by sending 'ping' request to all cluster nodes.
#
# GET /{realm}/clients/{id}/test-nodes-available
export def "clients-test-nodes-available get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<failedRequests: list<string>, successRequests: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/clients/($id)/test-nodes-available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user sessions for client   Returns a list of user sessions associated with this client
#
# GET /{realm}/clients/{id}/user-sessions
export def "clients-user-sessions get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first: int # Paging offset (format: int32)
  --max: int # Maximum results size (defaults to 100) (format: int32)
]: nothing -> table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/clients/($id)/user-sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{realm}/components
export def "components list" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --parent: string
  --type: string
]: nothing -> table<config: record<empty: bool, loadFactor: float, threshold: int>, id: string, name: string, parentId: string, providerId: string, providerType: string, subType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/components" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{realm}/components
#
# --config shape: {empty?: bool, loadFactor?: float, threshold?: int}
export def "components post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record # shape: {empty?: bool, loadFactor?: float, threshold?: int}
  --id: string
  --name: string
  --parentId: string
  --providerId: string
  --providerType: string
  --subType: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/components")
  let body = {config: $config, id: $id, name: $name, parentId: $parentId, providerId: $providerId, providerType: $providerType, subType: $subType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /{realm}/components/{id}
export def "components delete" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/components/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{realm}/components/{id}
export def "components get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config: record<empty: bool, loadFactor: float, threshold: int>, id: string, name: string, parentId: string, providerId: string, providerType: string, subType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/components/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /{realm}/components/{id}
#
# --config shape: {empty?: bool, loadFactor?: float, threshold?: int}
export def "components put" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record # shape: {empty?: bool, loadFactor?: float, threshold?: int}
  --body-id: string
  --name: string
  --parentId: string
  --providerId: string
  --providerType: string
  --subType: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/components/($id)")
  let body = {config: $config, id: $body_id, name: $name, parentId: $parentId, providerId: $providerId, providerType: $providerType, subType: $subType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List of subcomponent types that are available to configure for a particular parent component.
#
# GET /{realm}/components/{id}/sub-component-types
export def "components-sub-component-types get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string
]: nothing -> table<helpText: string, id: string, metadata: record, properties: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/components/($id)/sub-component-types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{realm}/credential-registrators
export def "credential-registrators get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/credential-registrators")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get realm default client scopes.
#
# GET /{realm}/default-default-client-scopes
export def "default-default-client-scopes get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/default-default-client-scopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /{realm}/default-default-client-scopes/{clientScopeId}
export def "default-default-client-scopes delete" [
  realm: string
  clientScopeId: string
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
  let full_url = (build-url $base $"/($realm)/default-default-client-scopes/($clientScopeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /{realm}/default-default-client-scopes/{clientScopeId}
export def "default-default-client-scopes put" [
  realm: string
  clientScopeId: string
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
  let full_url = (build-url $base $"/($realm)/default-default-client-scopes/($clientScopeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group hierarchy.
#
# GET /{realm}/default-groups
export def "default-groups get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/default-groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /{realm}/default-groups/{groupId}
export def "default-groups delete" [
  realm: string
  groupId: string
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
  let full_url = (build-url $base $"/($realm)/default-groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /{realm}/default-groups/{groupId}
export def "default-groups put" [
  realm: string
  groupId: string
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
  let full_url = (build-url $base $"/($realm)/default-groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get realm optional client scopes.
#
# GET /{realm}/default-optional-client-scopes
export def "default-optional-client-scopes get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/default-optional-client-scopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /{realm}/default-optional-client-scopes/{clientScopeId}
export def "default-optional-client-scopes delete" [
  realm: string
  clientScopeId: string
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
  let full_url = (build-url $base $"/($realm)/default-optional-client-scopes/($clientScopeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /{realm}/default-optional-client-scopes/{clientScopeId}
export def "default-optional-client-scopes put" [
  realm: string
  clientScopeId: string
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
  let full_url = (build-url $base $"/($realm)/default-optional-client-scopes/($clientScopeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete all events
#
# DELETE /{realm}/events
export def "events delete" [
  realm: string
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
  let full_url = (build-url $base $"/($realm)/events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get events   Returns all events, or filters them based on URL query parameters listed here
#
# GET /{realm}/events
export def "events get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client: string # App or oauth client name
  --dateFrom: string # From date
  --dateTo: string # To date
  --first: int # Paging offset (format: int32)
  --ipAddress: string # IP address
  --max: int # Maximum results size (defaults to 100) (format: int32)
  --type: list # The types of events to return
  --user: string # User id
]: nothing -> table<clientId: string, details: record, error: string, ipAddress: string, realmId: string, sessionId: string, time: int, type: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client" $client "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "ipAddress" $ipAddress "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "type" $type "multi") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the events provider configuration   Returns JSON object with events provider configuration
#
# GET /{realm}/events/config
export def "events-config get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<adminEventsDetailsEnabled: bool, adminEventsEnabled: bool, enabledEventTypes: list<string>, eventsEnabled: bool, eventsExpiration: int, eventsListeners: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/events/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the events provider   Change the events provider and/or its configuration
#
# PUT /{realm}/events/config
export def "events-config put" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --adminEventsDetailsEnabled: oneof<nothing, bool>
  --adminEventsEnabled: oneof<nothing, bool>
  --enabledEventTypes: list
  --eventsEnabled: oneof<nothing, bool>
  --eventsExpiration: int # format: int64
  --eventsListeners: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/events/config")
  let body = {adminEventsDetailsEnabled: $adminEventsDetailsEnabled, adminEventsEnabled: $adminEventsEnabled, enabledEventTypes: $enabledEventTypes, eventsEnabled: $eventsEnabled, eventsExpiration: $eventsExpiration, eventsListeners: $eventsListeners} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /{realm}/group-by-path/{path}
export def "group-by-path get" [
  realm: string
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/group-by-path/($path)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get group hierarchy.
#
# GET /{realm}/groups
export def "groups list" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --briefRepresentation: oneof<nothing, bool>
  --first: int # format: int32
  --max: int # format: int32
  --search: string
]: nothing -> table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "briefRepresentation" $briefRepresentation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create or add a top level realm groupSet or create child.
#
# POST /{realm}/groups
# --subGroups item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list, subGroups?: list}
export def "groups post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --attributes: record
  --clientRoles: record
  --id: string
  --name: string
  --path: string
  --realmRoles: list
  --subGroups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list, subGroups?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups")
  let body = {access: $access, attributes: $attributes, clientRoles: $clientRoles, id: $id, name: $name, path: $path, realmRoles: $realmRoles, subGroups: $subGroups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the groups counts.
#
# GET /{realm}/groups/count
export def "groups-count get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
  --top: oneof<nothing, bool>
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/groups/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /{realm}/groups/{id}
export def "groups delete" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{realm}/groups/{id}
export def "groups get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update group, ignores subgroups.
#
# PUT /{realm}/groups/{id}
# --subGroups item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list, subGroups?: list}
export def "groups put" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --attributes: record
  --clientRoles: record
  --body-id: string
  --name: string
  --path: string
  --realmRoles: list
  --subGroups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list, subGroups?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups/($id)")
  let body = {access: $access, attributes: $attributes, clientRoles: $clientRoles, id: $body_id, name: $name, path: $path, realmRoles: $realmRoles, subGroups: $subGroups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set or create child.
#
# POST /{realm}/groups/{id}/children
# --subGroups item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list, subGroups?: list}
export def "groups-children post" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --attributes: record
  --clientRoles: record
  --body-id: string
  --name: string
  --path: string
  --realmRoles: list
  --subGroups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list, subGroups?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups/($id)/children")
  let body = {access: $access, attributes: $attributes, clientRoles: $clientRoles, id: $body_id, name: $name, path: $path, realmRoles: $realmRoles, subGroups: $subGroups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# GET /{realm}/groups/{id}/management/permissions
export def "groups-management-permissions get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups/($id)/management/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# PUT /{realm}/groups/{id}/management/permissions
export def "groups-management-permissions put" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scopePermissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups/($id)/management/permissions")
  let body = {enabled: $enabled, resource: $resource, scopePermissions: $scopePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get users   Returns a list of users, filtered according to query parameters
#
# GET /{realm}/groups/{id}/members
export def "groups-members get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --briefRepresentation: oneof<nothing, bool> # Only return basic information (only guaranteed to return id, username, created, first and last name,  email, enabled state, email verification state, federation link, and access.  Note that it means that namely user attributes, required actions, and not before are not returned.)
  --first: int # Pagination offset (format: int32)
  --max: int # Maximum results size (defaults to 100) (format: int32)
]: nothing -> table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "briefRepresentation" $briefRepresentation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/groups/($id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get role mappings
#
# GET /{realm}/groups/{id}/role-mappings
export def "groups-role-mappings get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups/($id)/role-mappings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete client-level roles from user role mapping
#
# DELETE /{realm}/groups/{id}/role-mappings/clients/{client}
export def "groups-role-mappings-clients delete" [
  realm: string
  id: string
  client: string
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
  let full_url = (build-url $base $"/($realm)/groups/($id)/role-mappings/clients/($client)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get client-level role mappings for the user, and the app
#
# GET /{realm}/groups/{id}/role-mappings/clients/{client}
export def "groups-role-mappings-clients get" [
  realm: string
  id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups/($id)/role-mappings/clients/($client)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add client-level roles to the user role mapping
#
# POST /{realm}/groups/{id}/role-mappings/clients/{client}
export def "groups-role-mappings-clients post" [
  realm: string
  id: string
  client: string
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
  let full_url = (build-url $base $"/($realm)/groups/($id)/role-mappings/clients/($client)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get available client-level roles that can be mapped to the user
#
# GET /{realm}/groups/{id}/role-mappings/clients/{client}/available
export def "groups-role-mappings-clients-available get" [
  realm: string
  id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups/($id)/role-mappings/clients/($client)/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get effective client-level role mappings   This recurses any composite roles
#
# GET /{realm}/groups/{id}/role-mappings/clients/{client}/composite
export def "groups-role-mappings-clients-composite get" [
  realm: string
  id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups/($id)/role-mappings/clients/($client)/composite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete realm-level role mappings
#
# DELETE /{realm}/groups/{id}/role-mappings/realm
export def "groups-role-mappings-realm delete" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/groups/($id)/role-mappings/realm")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get realm-level role mappings
#
# GET /{realm}/groups/{id}/role-mappings/realm
export def "groups-role-mappings-realm get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups/($id)/role-mappings/realm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add realm-level role mappings to the user
#
# POST /{realm}/groups/{id}/role-mappings/realm
export def "groups-role-mappings-realm post" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/groups/($id)/role-mappings/realm")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get realm-level roles that can be mapped
#
# GET /{realm}/groups/{id}/role-mappings/realm/available
export def "groups-role-mappings-realm-available get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups/($id)/role-mappings/realm/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get effective realm-level role mappings   This will recurse all composite roles to get the result.
#
# GET /{realm}/groups/{id}/role-mappings/realm/composite
export def "groups-role-mappings-realm-composite get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/groups/($id)/role-mappings/realm/composite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import identity provider from uploaded JSON file
#
# POST /{realm}/identity-provider/import-config
export def "identity-provider-import-config post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/identity-provider/import-config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get identity providers
#
# GET /{realm}/identity-provider/instances
export def "identity-provider-instances list" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/identity-provider/instances")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new identity provider
#
# POST /{realm}/identity-provider/instances
export def "identity-provider-instances post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --addReadTokenRoleOnCreate: oneof<nothing, bool>
  --alias: string
  --config: record
  --displayName: string
  --enabled: oneof<nothing, bool>
  --firstBrokerLoginFlowAlias: string
  --internalId: string
  --linkOnly: oneof<nothing, bool>
  --postBrokerLoginFlowAlias: string
  --providerId: string
  --storeToken: oneof<nothing, bool>
  --trustEmail: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/identity-provider/instances")
  let body = {addReadTokenRoleOnCreate: $addReadTokenRoleOnCreate, alias: $alias, config: $config, displayName: $displayName, enabled: $enabled, firstBrokerLoginFlowAlias: $firstBrokerLoginFlowAlias, internalId: $internalId, linkOnly: $linkOnly, postBrokerLoginFlowAlias: $postBrokerLoginFlowAlias, providerId: $providerId, storeToken: $storeToken, trustEmail: $trustEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the identity provider
#
# DELETE /{realm}/identity-provider/instances/{alias}
export def "identity-provider-instances delete" [
  realm: string
  alias: string
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
  let full_url = (build-url $base $"/($realm)/identity-provider/instances/($alias)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the identity provider
#
# GET /{realm}/identity-provider/instances/{alias}
export def "identity-provider-instances get" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/identity-provider/instances/($alias)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the identity provider
#
# PUT /{realm}/identity-provider/instances/{alias}
export def "identity-provider-instances put" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --addReadTokenRoleOnCreate: oneof<nothing, bool>
  --body-alias: string
  --config: record
  --displayName: string
  --enabled: oneof<nothing, bool>
  --firstBrokerLoginFlowAlias: string
  --internalId: string
  --linkOnly: oneof<nothing, bool>
  --postBrokerLoginFlowAlias: string
  --providerId: string
  --storeToken: oneof<nothing, bool>
  --trustEmail: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/identity-provider/instances/($alias)")
  let body = {addReadTokenRoleOnCreate: $addReadTokenRoleOnCreate, alias: $body_alias, config: $config, displayName: $displayName, enabled: $enabled, firstBrokerLoginFlowAlias: $firstBrokerLoginFlowAlias, internalId: $internalId, linkOnly: $linkOnly, postBrokerLoginFlowAlias: $postBrokerLoginFlowAlias, providerId: $providerId, storeToken: $storeToken, trustEmail: $trustEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export public broker configuration for identity provider
#
# GET /{realm}/identity-provider/instances/{alias}/export
export def "identity-provider-instances-export get" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Format to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/identity-provider/instances/($alias)/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# GET /{realm}/identity-provider/instances/{alias}/management/permissions
export def "identity-provider-instances-management-permissions get" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/identity-provider/instances/($alias)/management/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# PUT /{realm}/identity-provider/instances/{alias}/management/permissions
export def "identity-provider-instances-management-permissions put" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scopePermissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/identity-provider/instances/($alias)/management/permissions")
  let body = {enabled: $enabled, resource: $resource, scopePermissions: $scopePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get mapper types for identity provider
#
# GET /{realm}/identity-provider/instances/{alias}/mapper-types
export def "identity-provider-instances-mapper-types get" [
  realm: string
  alias: string
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
  let full_url = (build-url $base $"/($realm)/identity-provider/instances/($alias)/mapper-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get mappers for identity provider
#
# GET /{realm}/identity-provider/instances/{alias}/mappers
export def "identity-provider-instances-mappers list" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/identity-provider/instances/($alias)/mappers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a mapper to identity provider
#
# POST /{realm}/identity-provider/instances/{alias}/mappers
export def "identity-provider-instances-mappers post" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --id: string
  --identityProviderAlias: string
  --identityProviderMapper: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/identity-provider/instances/($alias)/mappers")
  let body = {config: $config, id: $id, identityProviderAlias: $identityProviderAlias, identityProviderMapper: $identityProviderMapper, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a mapper for the identity provider
#
# DELETE /{realm}/identity-provider/instances/{alias}/mappers/{id}
export def "identity-provider-instances-mappers delete" [
  realm: string
  alias: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/identity-provider/instances/($alias)/mappers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get mapper by id for the identity provider
#
# GET /{realm}/identity-provider/instances/{alias}/mappers/{id}
export def "identity-provider-instances-mappers get" [
  realm: string
  alias: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/identity-provider/instances/($alias)/mappers/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a mapper for the identity provider
#
# PUT /{realm}/identity-provider/instances/{alias}/mappers/{id}
export def "identity-provider-instances-mappers put" [
  realm: string
  alias: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --body-id: string
  --identityProviderAlias: string
  --identityProviderMapper: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/identity-provider/instances/($alias)/mappers/($id)")
  let body = {config: $config, id: $body_id, identityProviderAlias: $identityProviderAlias, identityProviderMapper: $identityProviderMapper, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get identity providers
#
# GET /{realm}/identity-provider/providers/{provider_id}
export def "identity-provider-providers get" [
  realm: string
  provider_id: string
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
  let full_url = (build-url $base $"/($realm)/identity-provider/providers/($provider_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{realm}/keys
export def "keys get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: record, keys: table<algorithm: string, certificate: string, kid: string, providerId: string, providerPriority: int, publicKey: string, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes all user sessions.
#
# POST /{realm}/logout-all
export def "logout-all post" [
  realm: string
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
  let full_url = (build-url $base $"/($realm)/logout-all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Partial export of existing realm into a JSON file.
#
# POST /{realm}/partial-export
export def "partial-export post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exportClients: oneof<nothing, bool>
  --exportGroupsAndRoles: oneof<nothing, bool>
]: nothing -> record<accessCodeLifespan: int, accessCodeLifespanLogin: int, accessCodeLifespanUserAction: int, accessTokenLifespan: int, accessTokenLifespanForImplicitFlow: int, accountTheme: string, actionTokenGeneratedByAdminLifespan: int, actionTokenGeneratedByUserLifespan: int, adminEventsDetailsEnabled: bool, adminEventsEnabled: bool, adminTheme: string, attributes: record, authenticationFlows: table<alias: string, authenticationExecutions: list, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool>, authenticatorConfig: table<alias: string, config: record, id: string>, browserFlow: string, browserSecurityHeaders: record, bruteForceProtected: bool, clientAuthenticationFlow: string, clientScopeMappings: record, clientScopes: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list>, clientSessionIdleTimeout: int, clientSessionMaxLifespan: int, clients: table<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list, defaultRoles: list, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list, origin: string, protocol: string, protocolMappers: list, publicClient: bool, redirectUris: list, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list>, components: record<empty: bool, loadFactor: float, threshold: int>, defaultDefaultClientScopes: list<string>, defaultGroups: list<string>, defaultLocale: string, defaultOptionalClientScopes: list<string>, defaultRoles: list<string>, defaultSignatureAlgorithm: string, directGrantFlow: string, displayName: string, displayNameHtml: string, dockerAuthenticationFlow: string, duplicateEmailsAllowed: bool, editUsernameAllowed: bool, emailTheme: string, enabled: bool, enabledEventTypes: list<string>, eventsEnabled: bool, eventsExpiration: int, eventsListeners: list<string>, failureFactor: int, federatedUsers: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, groups: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list, subGroups: list>, id: string, identityProviderMappers: table<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string>, identityProviders: table<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool>, internationalizationEnabled: bool, keycloakVersion: string, loginTheme: string, loginWithEmailAllowed: bool, maxDeltaTimeSeconds: int, maxFailureWaitSeconds: int, minimumQuickLoginWaitSeconds: int, notBefore: int, offlineSessionIdleTimeout: int, offlineSessionMaxLifespan: int, offlineSessionMaxLifespanEnabled: bool, otpPolicyAlgorithm: string, otpPolicyDigits: int, otpPolicyInitialCounter: int, otpPolicyLookAheadWindow: int, otpPolicyPeriod: int, otpPolicyType: string, otpSupportedApplications: list<string>, passwordPolicy: string, permanentLockout: bool, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, quickLoginCheckMilliSeconds: int, realm: string, refreshTokenMaxReuse: int, registrationAllowed: bool, registrationEmailAsUsername: bool, registrationFlow: string, rememberMe: bool, requiredActions: table<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string>, resetCredentialsFlow: string, resetPasswordAllowed: bool, revokeRefreshToken: bool, roles: record<client: record, realm: list<record>>, scopeMappings: table<client: string, clientScope: string, roles: list, self: string>, smtpServer: record, sslRequired: string, ssoSessionIdleTimeout: int, ssoSessionIdleTimeoutRememberMe: int, ssoSessionMaxLifespan: int, ssoSessionMaxLifespanRememberMe: int, supportedLocales: list<string>, userFederationMappers: table<config: record, federationMapperType: string, federationProviderDisplayName: string, id: string, name: string>, userFederationProviders: table<changedSyncPeriod: int, config: record, displayName: string, fullSyncPeriod: int, id: string, lastSync: int, priority: int, providerName: string>, userManagedAccessAllowed: bool, users: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, verifyEmail: bool, waitIncrementSeconds: int, webAuthnPolicyAcceptableAaguids: list<string>, webAuthnPolicyAttestationConveyancePreference: string, webAuthnPolicyAuthenticatorAttachment: string, webAuthnPolicyAvoidSameAuthenticatorRegister: bool, webAuthnPolicyCreateTimeout: int, webAuthnPolicyPasswordlessAcceptableAaguids: list<string>, webAuthnPolicyPasswordlessAttestationConveyancePreference: string, webAuthnPolicyPasswordlessAuthenticatorAttachment: string, webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister: bool, webAuthnPolicyPasswordlessCreateTimeout: int, webAuthnPolicyPasswordlessRequireResidentKey: string, webAuthnPolicyPasswordlessRpEntityName: string, webAuthnPolicyPasswordlessRpId: string, webAuthnPolicyPasswordlessSignatureAlgorithms: list<string>, webAuthnPolicyPasswordlessUserVerificationRequirement: string, webAuthnPolicyRequireResidentKey: string, webAuthnPolicyRpEntityName: string, webAuthnPolicyRpId: string, webAuthnPolicySignatureAlgorithms: list<string>, webAuthnPolicyUserVerificationRequirement: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exportClients" $exportClients "scalar") (serialize-qp "exportGroupsAndRoles" $exportGroupsAndRoles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/partial-export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Partial import from a JSON file to an existing realm.
#
# POST /{realm}/partialImport
# --clients item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list, defaultRoles?: list, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, fullScopeAllowed?: bool, id?: string, implicitFlowEnabled?: bool, name?: string, nodeReRegistrationTimeout?: int, notBefore?: int, optionalClientScopes?: list, origin?: string, protocol?: string, protocolMappers?: list, publicClient?: bool, redirectUris?: list, registeredNodes?: record, registrationAccessToken?: string, rootUrl?: string, secret?: string, serviceAccountsEnabled?: bool, standardFlowEnabled?: bool, surrogateAuthRequired?: bool, webOrigins?: list}
# --groups item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list, subGroups?: list}
# --identityProviders item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
# --roles shape: {client?: record, realm?: list}
# --users item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list, requiredActions?: list, self?: string, serviceAccountClientId?: string, username?: string}
export def "partial-import post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clients: list # item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list, defaultRoles?: list, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, fullScopeAllowed?: bool, id?: string, implicitFlowEnabled?: bool, name?: string, nodeReRegistrationTimeout?: int, notBefore?: int, optionalClientScopes?: list, origin?: string, protocol?: string, protocolMappers?: list, publicClient?: bool, redirectUris?: list, registeredNodes?: record, registrationAccessToken?: string, rootUrl?: string, secret?: string, serviceAccountsEnabled?: bool, standardFlowEnabled?: bool, surrogateAuthRequired?: bool, webOrigins?: list}
  --groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list, subGroups?: list}
  --identityProviders: list # item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
  --ifResourceExists: string
  --policy: string@policy-completer
  --roles: record # shape: {client?: record, realm?: list}
  --users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list, requiredActions?: list, self?: string, serviceAccountClientId?: string, username?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/partialImport")
  let body = {clients: $clients, groups: $groups, identityProviders: $identityProviders, ifResourceExists: $ifResourceExists, policy: $policy, roles: $roles, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Push the realm’s revocation policy to any client that has an admin url associated with it.
#
# POST /{realm}/push-revocation
export def "push-revocation post" [
  realm: string
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
  let full_url = (build-url $base $"/($realm)/push-revocation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all roles for the realm or client
#
# GET /{realm}/roles
export def "roles list" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --briefRepresentation: oneof<nothing, bool>
  --first: int # format: int32
  --max: int # format: int32
  --search: string
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "briefRepresentation" $briefRepresentation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new role for the realm or client
#
# POST /{realm}/roles
# --composites shape: {client?: record, realm?: list}
export def "roles post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --clientRole: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list}
  --containerId: string
  --description: string
  --id: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles")
  let body = {attributes: $attributes, clientRole: $clientRole, composite: $composite, composites: $composites, containerId: $containerId, description: $description, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the role
#
# DELETE /{realm}/roles-by-id/{role-id}
export def "roles-by-id delete" [
  realm: string
  role_id: string
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
  let full_url = (build-url $base $"/($realm)/roles-by-id/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific role’s representation
#
# GET /{realm}/roles-by-id/{role-id}
export def "roles-by-id get" [
  realm: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list<string>>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles-by-id/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the role
#
# PUT /{realm}/roles-by-id/{role-id}
# --composites shape: {client?: record, realm?: list}
export def "roles-by-id put" [
  realm: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --clientRole: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list}
  --containerId: string
  --description: string
  --id: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles-by-id/($role_id)")
  let body = {attributes: $attributes, clientRole: $clientRole, composite: $composite, composites: $composites, containerId: $containerId, description: $description, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a set of roles from the role’s composite
#
# DELETE /{realm}/roles-by-id/{role-id}/composites
export def "roles-by-id-composites delete" [
  realm: string
  role_id: string
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
  let full_url = (build-url $base $"/($realm)/roles-by-id/($role_id)/composites")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get role’s children   Returns a set of role’s children provided the role is a composite.
#
# GET /{realm}/roles-by-id/{role-id}/composites
export def "roles-by-id-composites get" [
  realm: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles-by-id/($role_id)/composites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Make the role a composite role by associating some child roles
#
# POST /{realm}/roles-by-id/{role-id}/composites
export def "roles-by-id-composites post" [
  realm: string
  role_id: string
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
  let full_url = (build-url $base $"/($realm)/roles-by-id/($role_id)/composites")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get client-level roles for the client that are in the role’s composite
#
# GET /{realm}/roles-by-id/{role-id}/composites/clients/{client}
export def "roles-by-id-composites-clients get" [
  realm: string
  role_id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles-by-id/($role_id)/composites/clients/($client)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get realm-level roles that are in the role’s composite
#
# GET /{realm}/roles-by-id/{role-id}/composites/realm
export def "roles-by-id-composites-realm get" [
  realm: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles-by-id/($role_id)/composites/realm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# GET /{realm}/roles-by-id/{role-id}/management/permissions
export def "roles-by-id-management-permissions get" [
  realm: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles-by-id/($role_id)/management/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# PUT /{realm}/roles-by-id/{role-id}/management/permissions
export def "roles-by-id-management-permissions put" [
  realm: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scopePermissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles-by-id/($role_id)/management/permissions")
  let body = {enabled: $enabled, resource: $resource, scopePermissions: $scopePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a role by name
#
# DELETE /{realm}/roles/{role-name}
export def "roles delete" [
  realm: string
  role_name: string
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
  let full_url = (build-url $base $"/($realm)/roles/($role_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a role by name
#
# GET /{realm}/roles/{role-name}
export def "roles get" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list<string>>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles/($role_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a role by name
#
# PUT /{realm}/roles/{role-name}
# --composites shape: {client?: record, realm?: list}
export def "roles put" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --clientRole: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list}
  --containerId: string
  --description: string
  --id: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles/($role_name)")
  let body = {attributes: $attributes, clientRole: $clientRole, composite: $composite, composites: $composites, containerId: $containerId, description: $description, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove roles from the role’s composite
#
# DELETE /{realm}/roles/{role-name}/composites
export def "roles-composites delete" [
  realm: string
  role_name: string
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
  let full_url = (build-url $base $"/($realm)/roles/($role_name)/composites")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get composites of the role
#
# GET /{realm}/roles/{role-name}/composites
export def "roles-composites get" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles/($role_name)/composites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a composite to the role
#
# POST /{realm}/roles/{role-name}/composites
export def "roles-composites post" [
  realm: string
  role_name: string
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
  let full_url = (build-url $base $"/($realm)/roles/($role_name)/composites")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# An app-level roles for the specified app for the role’s composite
#
# GET /{realm}/roles/{role-name}/composites/clients/{client}
export def "roles-composites-clients get" [
  realm: string
  role_name: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles/($role_name)/composites/clients/($client)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get realm-level roles of the role’s composite
#
# GET /{realm}/roles/{role-name}/composites/realm
export def "roles-composites-realm get" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles/($role_name)/composites/realm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return List of Groups that have the specified role name
#
# GET /{realm}/roles/{role-name}/groups
export def "roles-groups get" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --briefRepresentation: oneof<nothing, bool> # if false, return a full representation of the GroupRepresentation objects
  --first: int # format: int32
  --max: int # format: int32
]: nothing -> table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "briefRepresentation" $briefRepresentation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/roles/($role_name)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# GET /{realm}/roles/{role-name}/management/permissions
export def "roles-management-permissions get" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles/($role_name)/management/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# PUT /{realm}/roles/{role-name}/management/permissions
export def "roles-management-permissions put" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scopePermissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/roles/($role_name)/management/permissions")
  let body = {enabled: $enabled, resource: $resource, scopePermissions: $scopePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return List of Users that have the specified role name
#
# GET /{realm}/roles/{role-name}/users
export def "roles-users get" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --first: int # format: int32
  --max: int # format: int32
]: nothing -> table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/roles/($role_name)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a specific user session.
#
# DELETE /{realm}/sessions/{session}
export def "sessions delete" [
  realm: string
  session: string
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
  let full_url = (build-url $base $"/($realm)/sessions/($session)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test LDAP connection
#
# POST /{realm}/testLDAPConnection
export def "test-ldap-connection post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string
  --bindCredential: string
  --bindDn: string
  --componentId: string
  --connectionTimeout: string
  --connectionUrl: string
  --startTls: string
  --useTruststoreSpi: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/testLDAPConnection")
  let body = {action: $action, bindCredential: $bindCredential, bindDn: $bindDn, componentId: $componentId, connectionTimeout: $connectionTimeout, connectionUrl: $connectionUrl, startTls: $startTls, useTruststoreSpi: $useTruststoreSpi} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /{realm}/testSMTPConnection
export def "test-smtp-connection post" [
  realm: string
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
  let full_url = (build-url $base $"/($realm)/testSMTPConnection")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Need this for admin console to display simple name of provider when displaying user detail   KEYCLOAK-4328
#
# GET /{realm}/user-storage/{id}/name
export def "user-storage-name get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/user-storage/($id)/name")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove imported users
#
# POST /{realm}/user-storage/{id}/remove-imported-users
export def "user-storage-remove-imported-users post" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/user-storage/($id)/remove-imported-users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger sync of users   Action can be "triggerFullSync" or "triggerChangedUsersSync"
#
# POST /{realm}/user-storage/{id}/sync
export def "user-storage-sync post" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string
]: nothing -> record<added: int, failed: int, ignored: bool, removed: int, status: string, updated: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/user-storage/($id)/sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unlink imported users from a storage provider
#
# POST /{realm}/user-storage/{id}/unlink-users
export def "user-storage-unlink-users post" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/user-storage/($id)/unlink-users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger sync of mapper data related to ldap mapper (roles, groups, …​)   direction is "fedToKeycloak" or "keycloakToFed"
#
# POST /{realm}/user-storage/{parentId}/mappers/{id}/sync
export def "user-storage-mappers-sync post" [
  realm: string
  parentId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string
]: nothing -> record<added: int, failed: int, ignored: bool, removed: int, status: string, updated: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/user-storage/($parentId)/mappers/($id)/sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users   Returns a list of users, filtered according to query parameters
#
# GET /{realm}/users
export def "users list" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --briefRepresentation: oneof<nothing, bool>
  --email: string
  --first: int # format: int32
  --firstName: string
  --lastName: string
  --max: int # Maximum results size (defaults to 100) (format: int32)
  --search: string # A String contained in username, first or last name, or email
  --username: string
]: nothing -> table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "briefRepresentation" $briefRepresentation "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "firstName" $firstName "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user   Username must be unique.
#
# POST /{realm}/users
# --clientConsents item shape: {clientId?: string, createdDate?: int, grantedClientScopes?: list, lastUpdatedDate?: int}
# --credentials item shape: {createdDate?: int, credentialData?: string, id?: string, priority?: int, secretData?: string, temporary?: bool, type?: string, userLabel?: string, value?: string}
# --federatedIdentities item shape: {identityProvider?: string, userId?: string, userName?: string}
export def "users post" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --attributes: record
  --clientConsents: list # item shape: {clientId?: string, createdDate?: int, grantedClientScopes?: list, lastUpdatedDate?: int}
  --clientRoles: record
  --createdTimestamp: int # format: int64
  --credentials: list # item shape: {createdDate?: int, credentialData?: string, id?: string, priority?: int, secretData?: string, temporary?: bool, type?: string, userLabel?: string, value?: string}
  --disableableCredentialTypes: list
  --email: string
  --emailVerified: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --federatedIdentities: list # item shape: {identityProvider?: string, userId?: string, userName?: string}
  --federationLink: string
  --firstName: string
  --groups: list
  --id: string
  --lastName: string
  --notBefore: int # format: int32
  --origin: string
  --realmRoles: list
  --requiredActions: list
  --self: string
  --serviceAccountClientId: string
  --username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users")
  let body = {access: $access, attributes: $attributes, clientConsents: $clientConsents, clientRoles: $clientRoles, createdTimestamp: $createdTimestamp, credentials: $credentials, disableableCredentialTypes: $disableableCredentialTypes, email: $email, emailVerified: $emailVerified, enabled: $enabled, federatedIdentities: $federatedIdentities, federationLink: $federationLink, firstName: $firstName, groups: $groups, id: $id, lastName: $lastName, notBefore: $notBefore, origin: $origin, realmRoles: $realmRoles, requiredActions: $requiredActions, self: $self, serviceAccountClientId: $serviceAccountClientId, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /{realm}/users-management-permissions
export def "users-management-permissions get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users-management-permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /{realm}/users-management-permissions
export def "users-management-permissions put" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scopePermissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users-management-permissions")
  let body = {enabled: $enabled, resource: $resource, scopePermissions: $scopePermissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the number of users that match the given criteria.
#
# GET /{realm}/users/count
export def "users-count get" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # email filter
  --firstName: string # first name filter
  --lastName: string # last name filter
  --search: string # arbitrary search string for all the fields below
  --username: string # username filter
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "firstName" $firstName "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/users/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the user
#
# DELETE /{realm}/users/{id}
export def "users delete" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get representation of the user
#
# GET /{realm}/users/{id}
export def "users get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access: record, attributes: record, clientConsents: table<clientId: string, createdDate: int, grantedClientScopes: list, lastUpdatedDate: int>, clientRoles: record, createdTimestamp: int, credentials: table<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: table<identityProvider: string, userId: string, userName: string>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the user
#
# PUT /{realm}/users/{id}
# --clientConsents item shape: {clientId?: string, createdDate?: int, grantedClientScopes?: list, lastUpdatedDate?: int}
# --credentials item shape: {createdDate?: int, credentialData?: string, id?: string, priority?: int, secretData?: string, temporary?: bool, type?: string, userLabel?: string, value?: string}
# --federatedIdentities item shape: {identityProvider?: string, userId?: string, userName?: string}
export def "users put" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --attributes: record
  --clientConsents: list # item shape: {clientId?: string, createdDate?: int, grantedClientScopes?: list, lastUpdatedDate?: int}
  --clientRoles: record
  --createdTimestamp: int # format: int64
  --credentials: list # item shape: {createdDate?: int, credentialData?: string, id?: string, priority?: int, secretData?: string, temporary?: bool, type?: string, userLabel?: string, value?: string}
  --disableableCredentialTypes: list
  --email: string
  --emailVerified: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --federatedIdentities: list # item shape: {identityProvider?: string, userId?: string, userName?: string}
  --federationLink: string
  --firstName: string
  --groups: list
  --body-id: string
  --lastName: string
  --notBefore: int # format: int32
  --origin: string
  --realmRoles: list
  --requiredActions: list
  --self: string
  --serviceAccountClientId: string
  --username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)")
  let body = {access: $access, attributes: $attributes, clientConsents: $clientConsents, clientRoles: $clientRoles, createdTimestamp: $createdTimestamp, credentials: $credentials, disableableCredentialTypes: $disableableCredentialTypes, email: $email, emailVerified: $emailVerified, enabled: $enabled, federatedIdentities: $federatedIdentities, federationLink: $federationLink, firstName: $firstName, groups: $groups, id: $body_id, lastName: $lastName, notBefore: $notBefore, origin: $origin, realmRoles: $realmRoles, requiredActions: $requiredActions, self: $self, serviceAccountClientId: $serviceAccountClientId, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return credential types, which are provided by the user storage where user is stored.
#
# GET /{realm}/users/{id}/configured-user-storage-credential-types
export def "users-configured-user-storage-credential-types get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/configured-user-storage-credential-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get consents granted by the user
#
# GET /{realm}/users/{id}/consents
export def "users-consents get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/consents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke consent and offline tokens for particular client from user
#
# DELETE /{realm}/users/{id}/consents/{client}
export def "users-consents delete" [
  realm: string
  id: string
  client: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/consents/($client)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{realm}/users/{id}/credentials
export def "users-credentials get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a credential for a user
#
# DELETE /{realm}/users/{id}/credentials/{credentialId}
export def "users-credentials delete" [
  realm: string
  id: string
  credentialId: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/credentials/($credentialId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move a credential to a position behind another credential
#
# POST /{realm}/users/{id}/credentials/{credentialId}/moveAfter/{newPreviousCredentialId}
export def "users-credentials-move-after post" [
  realm: string
  id: string
  credentialId: string
  newPreviousCredentialId: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/credentials/($credentialId)/moveAfter/($newPreviousCredentialId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move a credential to a first position in the credentials list of the user
#
# POST /{realm}/users/{id}/credentials/{credentialId}/moveToFirst
export def "users-credentials-move-to-first post" [
  realm: string
  id: string
  credentialId: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/credentials/($credentialId)/moveToFirst")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a credential label for a user
#
# PUT /{realm}/users/{id}/credentials/{credentialId}/userLabel
export def "users-credentials-user-label put" [
  realm: string
  id: string
  credentialId: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/credentials/($credentialId)/userLabel")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "text/plain" $body
}

# Disable all credentials for a user of a specific type
#
# PUT /{realm}/users/{id}/disable-credential-types
export def "users-disable-credential-types put" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/disable-credential-types")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a update account email to the user   An email contains a link the user can click to perform a set of required actions.
#
# PUT /{realm}/users/{id}/execute-actions-email
export def "users-execute-actions-email put" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Client id
  --lifespan: int # Number of seconds after which the generated token expires (format: int32)
  --redirect-uri: string # Redirect uri
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "lifespan" $lifespan "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/users/($id)/execute-actions-email" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get social logins associated with the user
#
# GET /{realm}/users/{id}/federated-identity
export def "users-federated-identity get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<identityProvider: string, userId: string, userName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/federated-identity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a social login provider from user
#
# DELETE /{realm}/users/{id}/federated-identity/{provider}
export def "users-federated-identity delete" [
  realm: string
  id: string
  provider: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/federated-identity/($provider)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a social login provider to the user
#
# POST /{realm}/users/{id}/federated-identity/{provider}
export def "users-federated-identity post" [
  realm: string
  id: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identityProvider: string
  --userId: string
  --userName: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/federated-identity/($provider)")
  let body = {identityProvider: $identityProvider, userId: $userId, userName: $userName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /{realm}/users/{id}/groups
export def "users-groups get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --briefRepresentation: oneof<nothing, bool>
  --first: int # format: int32
  --max: int # format: int32
  --search: string
]: nothing -> table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "briefRepresentation" $briefRepresentation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/users/($id)/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /{realm}/users/{id}/groups/count
export def "users-groups-count get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/users/($id)/groups/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /{realm}/users/{id}/groups/{groupId}
export def "users-groups delete" [
  realm: string
  id: string
  groupId: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /{realm}/users/{id}/groups/{groupId}
export def "users-groups put" [
  realm: string
  id: string
  groupId: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Impersonate the user
#
# POST /{realm}/users/{id}/impersonation
export def "users-impersonation post" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/impersonation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove all user sessions associated with the user   Also send notification to all clients that have an admin URL to invalidate the sessions for the particular user.
#
# POST /{realm}/users/{id}/logout
export def "users-logout post" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get offline sessions associated with the user and client
#
# GET /{realm}/users/{id}/offline-sessions/{clientId}
export def "users-offline-sessions get" [
  realm: string
  id: string
  clientId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/offline-sessions/($clientId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set up a new password for the user.
#
# PUT /{realm}/users/{id}/reset-password
export def "users-reset-password put" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --createdDate: int # format: int64
  --credentialData: string
  --body-id: string
  --priority: int # format: int32
  --secretData: string
  --temporary: oneof<nothing, bool>
  --type: string
  --userLabel: string
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/reset-password")
  let body = {createdDate: $createdDate, credentialData: $credentialData, id: $body_id, priority: $priority, secretData: $secretData, temporary: $temporary, type: $type, userLabel: $userLabel, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get role mappings
#
# GET /{realm}/users/{id}/role-mappings
export def "users-role-mappings get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/role-mappings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete client-level roles from user role mapping
#
# DELETE /{realm}/users/{id}/role-mappings/clients/{client}
export def "users-role-mappings-clients delete" [
  realm: string
  id: string
  client: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/role-mappings/clients/($client)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get client-level role mappings for the user, and the app
#
# GET /{realm}/users/{id}/role-mappings/clients/{client}
export def "users-role-mappings-clients get" [
  realm: string
  id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/role-mappings/clients/($client)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add client-level roles to the user role mapping
#
# POST /{realm}/users/{id}/role-mappings/clients/{client}
export def "users-role-mappings-clients post" [
  realm: string
  id: string
  client: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/role-mappings/clients/($client)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get available client-level roles that can be mapped to the user
#
# GET /{realm}/users/{id}/role-mappings/clients/{client}/available
export def "users-role-mappings-clients-available get" [
  realm: string
  id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/role-mappings/clients/($client)/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get effective client-level role mappings   This recurses any composite roles
#
# GET /{realm}/users/{id}/role-mappings/clients/{client}/composite
export def "users-role-mappings-clients-composite get" [
  realm: string
  id: string
  client: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/role-mappings/clients/($client)/composite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete realm-level role mappings
#
# DELETE /{realm}/users/{id}/role-mappings/realm
export def "users-role-mappings-realm delete" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/role-mappings/realm")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get realm-level role mappings
#
# GET /{realm}/users/{id}/role-mappings/realm
export def "users-role-mappings-realm get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/role-mappings/realm")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add realm-level role mappings to the user
#
# POST /{realm}/users/{id}/role-mappings/realm
export def "users-role-mappings-realm post" [
  realm: string
  id: string
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
  let full_url = (build-url $base $"/($realm)/users/($id)/role-mappings/realm")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get realm-level roles that can be mapped
#
# GET /{realm}/users/{id}/role-mappings/realm/available
export def "users-role-mappings-realm-available get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/role-mappings/realm/available")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get effective realm-level role mappings   This will recurse all composite roles to get the result.
#
# GET /{realm}/users/{id}/role-mappings/realm/composite
export def "users-role-mappings-realm-composite get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/role-mappings/realm/composite")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send an email-verification email to the user   An email contains a link the user can click to verify their email address.
#
# PUT /{realm}/users/{id}/send-verify-email
export def "users-send-verify-email put" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Client id
  --redirect-uri: string # Redirect uri
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($realm)/users/($id)/send-verify-email" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sessions associated with the user
#
# GET /{realm}/users/{id}/sessions
export def "users-sessions get" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($realm)/users/($id)/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
