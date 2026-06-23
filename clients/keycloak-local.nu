# Auto-generated client for Keycloak Admin REST API v1
# Source: https://api.apis.guru/v2/specs/keycloak.local/1/openapi.json
# Auth: --token flag or $env.KEYCLOAK_ADMIN_REST_API_TOKEN

const BASE_URL = "http://keycloak.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KEYCLOAK_ADMIN_REST_API_TOKEN | default "" }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["http://keycloak.local"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def policy-completer [] { ["FAIL" "OVERWRITE" "SKIP"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<builtinProtocolMappers: record, clientImporters: list<record>, clientInstallations: record, componentTypes: record, enums: record, identityProviders: list<record>, memoryInfo: record<free: int, freeFormated: string, freePercentage: int, total: int, totalFormated: string, used: int, usedFormated: string>, passwordPolicies: table<configType: string, defaultValue: string, displayName: string, id: string, multipleSupported: bool>, profileInfo: record<disabledFeatures: list<string>, experimentalFeatures: list<string>, name: string, previewFeatures: list<string>>, protocolMapperTypes: record, providers: record, socialProviders: list<record>, systemInfo: record<fileEncoding: string, javaHome: string, javaRuntime: string, javaVendor: string, javaVersion: string, javaVm: string, javaVmVersion: string, osArchitecture: string, osName: string, osVersion: string, serverTime: string, uptime: string, uptimeMillis: int, userDir: string, userLocale: string, userName: string, userTimezone: string, version: string>, themes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Import a realm Imports a realm from a full representation of that realm.
#
# POST /
# --authenticationFlows item shape: {alias?: string, authenticationExecutions?: list, builtIn?: bool, description?: string, id?: string, providerId?: string, topLevel?: bool}
# --authenticatorConfig item shape: {alias?: string, config?: record, id?: string}
# --clientScopes item shape: {attributes?: record, description?: string, id?: string, name?: string, protocol?: string, protocolMappers?: list}
# --clients item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list<string>, defaultRoles?: list<string>, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, ... (20 more fields)}
# --components shape: {empty?: bool, loadFactor?: float, threshold?: int}
# --federatedUsers item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
# --groups item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
# --identityProviderMappers item shape: {config?: record, id?: string, identityProviderAlias?: string, identityProviderMapper?: string, name?: string}
# --identityProviders item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
# --protocolMappers item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
# --requiredActions item shape: {alias?: string, config?: record, defaultAction?: bool, enabled?: bool, name?: string, priority?: int, providerId?: string}
# --roles shape: {client?: record, realm?: list}
# --scopeMappings item shape: {client?: string, clientScope?: string, roles?: list<string>, self?: string}
# --userFederationMappers item shape: {config?: record, federationMapperType?: string, federationProviderDisplayName?: string, id?: string, name?: string}
# --userFederationProviders item shape: {changedSyncPeriod?: int, config?: record, displayName?: string, fullSyncPeriod?: int, id?: string, lastSync?: int, priority?: int, providerName?: string}
# --users item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
export def "realms-admin create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-code-lifespan: int # format: int32
  --access-code-lifespan-login: int # format: int32
  --access-code-lifespan-user-action: int # format: int32
  --access-token-lifespan: int # format: int32
  --access-token-lifespan-for-implicit-flow: int # format: int32
  --account-theme: string
  --action-token-generated-by-admin-lifespan: int # format: int32
  --action-token-generated-by-user-lifespan: int # format: int32
  --admin-events-details-enabled: oneof<nothing, bool>
  --admin-events-enabled: oneof<nothing, bool>
  --admin-theme: string
  --attributes: record
  --authentication-flows: list # item shape: {alias?: string, authenticationExecutions?: list, builtIn?: bool, description?: string, id?: string, providerId?: string, topLevel?: bool}
  --authenticator-config: list # item shape: {alias?: string, config?: record, id?: string}
  --browser-flow: string
  --browser-security-headers: record
  --brute-force-protected: oneof<nothing, bool>
  --client-authentication-flow: string
  --client-scope-mappings: record
  --client-scopes: list # item shape: {attributes?: record, description?: string, id?: string, name?: string, protocol?: string, protocolMappers?: list}
  --client-session-idle-timeout: int # format: int32
  --client-session-max-lifespan: int # format: int32
  --clients: list # item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list<string>, defaultRoles?: list<string>, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, ... (20 more fields)}
  --components: record # shape: {empty?: bool, loadFactor?: float, threshold?: int}
  --default-default-client-scopes: list<string>
  --default-groups: list<string>
  --default-locale: string
  --default-optional-client-scopes: list<string>
  --default-roles: list<string>
  --default-signature-algorithm: string
  --direct-grant-flow: string
  --display-name: string
  --display-name-html: string
  --docker-authentication-flow: string
  --duplicate-emails-allowed: oneof<nothing, bool>
  --edit-username-allowed: oneof<nothing, bool>
  --email-theme: string
  --enabled: oneof<nothing, bool>
  --enabled-event-types: list<string>
  --events-enabled: oneof<nothing, bool>
  --events-expiration: int # format: int64
  --events-listeners: list<string>
  --failure-factor: int # format: int32
  --federated-users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
  --groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
  --id: string
  --identity-provider-mappers: list # item shape: {config?: record, id?: string, identityProviderAlias?: string, identityProviderMapper?: string, name?: string}
  --identity-providers: list # item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
  --internationalization-enabled: oneof<nothing, bool>
  --keycloak-version: string
  --login-theme: string
  --login-with-email-allowed: oneof<nothing, bool>
  --max-delta-time-seconds: int # format: int32
  --max-failure-wait-seconds: int # format: int32
  --minimum-quick-login-wait-seconds: int # format: int32
  --not-before: int # format: int32
  --offline-session-idle-timeout: int # format: int32
  --offline-session-max-lifespan: int # format: int32
  --offline-session-max-lifespan-enabled: oneof<nothing, bool>
  --otp-policy-algorithm: string
  --otp-policy-digits: int # format: int32
  --otp-policy-initial-counter: int # format: int32
  --otp-policy-look-ahead-window: int # format: int32
  --otp-policy-period: int # format: int32
  --otp-policy-type: string
  --otp-supported-applications: list<string>
  --password-policy: string
  --permanent-lockout: oneof<nothing, bool>
  --protocol-mappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
  --quick-login-check-milli-seconds: int # format: int64
  --realm: string
  --refresh-token-max-reuse: int # format: int32
  --registration-allowed: oneof<nothing, bool>
  --registration-email-as-username: oneof<nothing, bool>
  --registration-flow: string
  --remember-me: oneof<nothing, bool>
  --required-actions: list # item shape: {alias?: string, config?: record, defaultAction?: bool, enabled?: bool, name?: string, priority?: int, providerId?: string}
  --reset-credentials-flow: string
  --reset-password-allowed: oneof<nothing, bool>
  --revoke-refresh-token: oneof<nothing, bool>
  --roles: record # shape: {client?: record, realm?: list}
  --scope-mappings: list # item shape: {client?: string, clientScope?: string, roles?: list<string>, self?: string}
  --smtp-server: record
  --ssl-required: string
  --sso-session-idle-timeout: int # format: int32
  --sso-session-idle-timeout-remember-me: int # format: int32
  --sso-session-max-lifespan: int # format: int32
  --sso-session-max-lifespan-remember-me: int # format: int32
  --supported-locales: list<string>
  --user-federation-mappers: list # item shape: {config?: record, federationMapperType?: string, federationProviderDisplayName?: string, id?: string, name?: string}
  --user-federation-providers: list # item shape: {changedSyncPeriod?: int, config?: record, displayName?: string, fullSyncPeriod?: int, id?: string, lastSync?: int, priority?: int, providerName?: string}
  --user-managed-access-allowed: oneof<nothing, bool>
  --users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
  --verify-email: oneof<nothing, bool>
  --wait-increment-seconds: int # format: int32
  --web-authn-policy-acceptable-aaguids: list<string>
  --web-authn-policy-attestation-conveyance-preference: string
  --web-authn-policy-authenticator-attachment: string
  --web-authn-policy-avoid-same-authenticator-register: oneof<nothing, bool>
  --web-authn-policy-create-timeout: int # format: int32
  --web-authn-policy-passwordless-acceptable-aaguids: list<string>
  --web-authn-policy-passwordless-attestation-conveyance-preference: string
  --web-authn-policy-passwordless-authenticator-attachment: string
  --web-authn-policy-passwordless-avoid-same-authenticator-register: oneof<nothing, bool>
  --web-authn-policy-passwordless-create-timeout: int # format: int32
  --web-authn-policy-passwordless-require-resident-key: string
  --web-authn-policy-passwordless-rp-entity-name: string
  --web-authn-policy-passwordless-rp-id: string
  --web-authn-policy-passwordless-signature-algorithms: list<string>
  --web-authn-policy-passwordless-user-verification-requirement: string
  --web-authn-policy-require-resident-key: string
  --web-authn-policy-rp-entity-name: string
  --web-authn-policy-rp-id: string
  --web-authn-policy-signature-algorithms: list<string>
  --web-authn-policy-user-verification-requirement: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let req_body = {"accessCodeLifespan": $access_code_lifespan, "accessCodeLifespanLogin": $access_code_lifespan_login, "accessCodeLifespanUserAction": $access_code_lifespan_user_action, "accessTokenLifespan": $access_token_lifespan, "accessTokenLifespanForImplicitFlow": $access_token_lifespan_for_implicit_flow, "accountTheme": $account_theme, "actionTokenGeneratedByAdminLifespan": $action_token_generated_by_admin_lifespan, "actionTokenGeneratedByUserLifespan": $action_token_generated_by_user_lifespan, "adminEventsDetailsEnabled": $admin_events_details_enabled, "adminEventsEnabled": $admin_events_enabled, "adminTheme": $admin_theme, "attributes": $attributes, "authenticationFlows": $authentication_flows, "authenticatorConfig": $authenticator_config, "browserFlow": $browser_flow, "browserSecurityHeaders": $browser_security_headers, "bruteForceProtected": $brute_force_protected, "clientAuthenticationFlow": $client_authentication_flow, "clientScopeMappings": $client_scope_mappings, "clientScopes": $client_scopes, "clientSessionIdleTimeout": $client_session_idle_timeout, "clientSessionMaxLifespan": $client_session_max_lifespan, "clients": $clients, "components": $components, "defaultDefaultClientScopes": $default_default_client_scopes, "defaultGroups": $default_groups, "defaultLocale": $default_locale, "defaultOptionalClientScopes": $default_optional_client_scopes, "defaultRoles": $default_roles, "defaultSignatureAlgorithm": $default_signature_algorithm, "directGrantFlow": $direct_grant_flow, "displayName": $display_name, "displayNameHtml": $display_name_html, "dockerAuthenticationFlow": $docker_authentication_flow, "duplicateEmailsAllowed": $duplicate_emails_allowed, "editUsernameAllowed": $edit_username_allowed, "emailTheme": $email_theme, "enabled": $enabled, "enabledEventTypes": $enabled_event_types, "eventsEnabled": $events_enabled, "eventsExpiration": $events_expiration, "eventsListeners": $events_listeners, "failureFactor": $failure_factor, "federatedUsers": $federated_users, "groups": $groups, "id": $id, "identityProviderMappers": $identity_provider_mappers, "identityProviders": $identity_providers, "internationalizationEnabled": $internationalization_enabled, "keycloakVersion": $keycloak_version, "loginTheme": $login_theme, "loginWithEmailAllowed": $login_with_email_allowed, "maxDeltaTimeSeconds": $max_delta_time_seconds, "maxFailureWaitSeconds": $max_failure_wait_seconds, "minimumQuickLoginWaitSeconds": $minimum_quick_login_wait_seconds, "notBefore": $not_before, "offlineSessionIdleTimeout": $offline_session_idle_timeout, "offlineSessionMaxLifespan": $offline_session_max_lifespan, "offlineSessionMaxLifespanEnabled": $offline_session_max_lifespan_enabled, "otpPolicyAlgorithm": $otp_policy_algorithm, "otpPolicyDigits": $otp_policy_digits, "otpPolicyInitialCounter": $otp_policy_initial_counter, "otpPolicyLookAheadWindow": $otp_policy_look_ahead_window, "otpPolicyPeriod": $otp_policy_period, "otpPolicyType": $otp_policy_type, "otpSupportedApplications": $otp_supported_applications, "passwordPolicy": $password_policy, "permanentLockout": $permanent_lockout, "protocolMappers": $protocol_mappers, "quickLoginCheckMilliSeconds": $quick_login_check_milli_seconds, "realm": $realm, "refreshTokenMaxReuse": $refresh_token_max_reuse, "registrationAllowed": $registration_allowed, "registrationEmailAsUsername": $registration_email_as_username, "registrationFlow": $registration_flow, "rememberMe": $remember_me, "requiredActions": $required_actions, "resetCredentialsFlow": $reset_credentials_flow, "resetPasswordAllowed": $reset_password_allowed, "revokeRefreshToken": $revoke_refresh_token, "roles": $roles, "scopeMappings": $scope_mappings, "smtpServer": $smtp_server, "sslRequired": $ssl_required, "ssoSessionIdleTimeout": $sso_session_idle_timeout, "ssoSessionIdleTimeoutRememberMe": $sso_session_idle_timeout_remember_me, "ssoSessionMaxLifespan": $sso_session_max_lifespan, "ssoSessionMaxLifespanRememberMe": $sso_session_max_lifespan_remember_me, "supportedLocales": $supported_locales, "userFederationMappers": $user_federation_mappers, "userFederationProviders": $user_federation_providers, "userManagedAccessAllowed": $user_managed_access_allowed, "users": $users, "verifyEmail": $verify_email, "waitIncrementSeconds": $wait_increment_seconds, "webAuthnPolicyAcceptableAaguids": $web_authn_policy_acceptable_aaguids, "webAuthnPolicyAttestationConveyancePreference": $web_authn_policy_attestation_conveyance_preference, "webAuthnPolicyAuthenticatorAttachment": $web_authn_policy_authenticator_attachment, "webAuthnPolicyAvoidSameAuthenticatorRegister": $web_authn_policy_avoid_same_authenticator_register, "webAuthnPolicyCreateTimeout": $web_authn_policy_create_timeout, "webAuthnPolicyPasswordlessAcceptableAaguids": $web_authn_policy_passwordless_acceptable_aaguids, "webAuthnPolicyPasswordlessAttestationConveyancePreference": $web_authn_policy_passwordless_attestation_conveyance_preference, "webAuthnPolicyPasswordlessAuthenticatorAttachment": $web_authn_policy_passwordless_authenticator_attachment, "webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister": $web_authn_policy_passwordless_avoid_same_authenticator_register, "webAuthnPolicyPasswordlessCreateTimeout": $web_authn_policy_passwordless_create_timeout, "webAuthnPolicyPasswordlessRequireResidentKey": $web_authn_policy_passwordless_require_resident_key, "webAuthnPolicyPasswordlessRpEntityName": $web_authn_policy_passwordless_rp_entity_name, "webAuthnPolicyPasswordlessRpId": $web_authn_policy_passwordless_rp_id, "webAuthnPolicyPasswordlessSignatureAlgorithms": $web_authn_policy_passwordless_signature_algorithms, "webAuthnPolicyPasswordlessUserVerificationRequirement": $web_authn_policy_passwordless_user_verification_requirement, "webAuthnPolicyRequireResidentKey": $web_authn_policy_require_resident_key, "webAuthnPolicyRpEntityName": $web_authn_policy_rp_entity_name, "webAuthnPolicyRpId": $web_authn_policy_rp_id, "webAuthnPolicySignatureAlgorithms": $web_authn_policy_signature_algorithms, "webAuthnPolicyUserVerificationRequirement": $web_authn_policy_user_verification_requirement} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Need this for admin console to display simple name of provider when displaying client detail KEYCLOAK-4328
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/{id}/name"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the top-level representation of the realm It will not include nested information like User and Client representations.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accessCodeLifespan: int, accessCodeLifespanLogin: int, accessCodeLifespanUserAction: int, accessTokenLifespan: int, accessTokenLifespanForImplicitFlow: int, accountTheme: string, actionTokenGeneratedByAdminLifespan: int, actionTokenGeneratedByUserLifespan: int, adminEventsDetailsEnabled: bool, adminEventsEnabled: bool, adminTheme: string, attributes: record, authenticationFlows: table<alias: string, authenticationExecutions: list, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool>, authenticatorConfig: table<alias: string, config: record, id: string>, browserFlow: string, browserSecurityHeaders: record, bruteForceProtected: bool, clientAuthenticationFlow: string, clientScopeMappings: record, clientScopes: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list>, clientSessionIdleTimeout: int, clientSessionMaxLifespan: int, clients: table<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list, defaultRoles: list, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list, origin: string, protocol: string, protocolMappers: list, publicClient: bool, redirectUris: list, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list>, components: record<empty: bool, loadFactor: float, threshold: int>, defaultDefaultClientScopes: list<string>, defaultGroups: list<string>, defaultLocale: string, defaultOptionalClientScopes: list<string>, defaultRoles: list<string>, defaultSignatureAlgorithm: string, directGrantFlow: string, displayName: string, displayNameHtml: string, dockerAuthenticationFlow: string, duplicateEmailsAllowed: bool, editUsernameAllowed: bool, emailTheme: string, enabled: bool, enabledEventTypes: list<string>, eventsEnabled: bool, eventsExpiration: int, eventsListeners: list<string>, failureFactor: int, federatedUsers: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, groups: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list, subGroups: list>, id: string, identityProviderMappers: table<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string>, identityProviders: table<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool>, internationalizationEnabled: bool, keycloakVersion: string, loginTheme: string, loginWithEmailAllowed: bool, maxDeltaTimeSeconds: int, maxFailureWaitSeconds: int, minimumQuickLoginWaitSeconds: int, notBefore: int, offlineSessionIdleTimeout: int, offlineSessionMaxLifespan: int, offlineSessionMaxLifespanEnabled: bool, otpPolicyAlgorithm: string, otpPolicyDigits: int, otpPolicyInitialCounter: int, otpPolicyLookAheadWindow: int, otpPolicyPeriod: int, otpPolicyType: string, otpSupportedApplications: list<string>, passwordPolicy: string, permanentLockout: bool, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, quickLoginCheckMilliSeconds: int, realm: string, refreshTokenMaxReuse: int, registrationAllowed: bool, registrationEmailAsUsername: bool, registrationFlow: string, rememberMe: bool, requiredActions: table<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string>, resetCredentialsFlow: string, resetPasswordAllowed: bool, revokeRefreshToken: bool, roles: record<client: record, realm: list<record>>, scopeMappings: table<client: string, clientScope: string, roles: list, self: string>, smtpServer: record, sslRequired: string, ssoSessionIdleTimeout: int, ssoSessionIdleTimeoutRememberMe: int, ssoSessionMaxLifespan: int, ssoSessionMaxLifespanRememberMe: int, supportedLocales: list<string>, userFederationMappers: table<config: record, federationMapperType: string, federationProviderDisplayName: string, id: string, name: string>, userFederationProviders: table<changedSyncPeriod: int, config: record, displayName: string, fullSyncPeriod: int, id: string, lastSync: int, priority: int, providerName: string>, userManagedAccessAllowed: bool, users: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, verifyEmail: bool, waitIncrementSeconds: int, webAuthnPolicyAcceptableAaguids: list<string>, webAuthnPolicyAttestationConveyancePreference: string, webAuthnPolicyAuthenticatorAttachment: string, webAuthnPolicyAvoidSameAuthenticatorRegister: bool, webAuthnPolicyCreateTimeout: int, webAuthnPolicyPasswordlessAcceptableAaguids: list<string>, webAuthnPolicyPasswordlessAttestationConveyancePreference: string, webAuthnPolicyPasswordlessAuthenticatorAttachment: string, webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister: bool, webAuthnPolicyPasswordlessCreateTimeout: int, webAuthnPolicyPasswordlessRequireResidentKey: string, webAuthnPolicyPasswordlessRpEntityName: string, webAuthnPolicyPasswordlessRpId: string, webAuthnPolicyPasswordlessSignatureAlgorithms: list<string>, webAuthnPolicyPasswordlessUserVerificationRequirement: string, webAuthnPolicyRequireResidentKey: string, webAuthnPolicyRpEntityName: string, webAuthnPolicyRpId: string, webAuthnPolicySignatureAlgorithms: list<string>, webAuthnPolicyUserVerificationRequirement: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the top-level information of the realm Any user, roles or client information in the representation will be ignored.
#
# PUT /{realm}
# --authenticationFlows item shape: {alias?: string, authenticationExecutions?: list, builtIn?: bool, description?: string, id?: string, providerId?: string, topLevel?: bool}
# --authenticatorConfig item shape: {alias?: string, config?: record, id?: string}
# --clientScopes item shape: {attributes?: record, description?: string, id?: string, name?: string, protocol?: string, protocolMappers?: list}
# --clients item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list<string>, defaultRoles?: list<string>, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, ... (20 more fields)}
# --components shape: {empty?: bool, loadFactor?: float, threshold?: int}
# --federatedUsers item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
# --groups item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
# --identityProviderMappers item shape: {config?: record, id?: string, identityProviderAlias?: string, identityProviderMapper?: string, name?: string}
# --identityProviders item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
# --protocolMappers item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
# --requiredActions item shape: {alias?: string, config?: record, defaultAction?: bool, enabled?: bool, name?: string, priority?: int, providerId?: string}
# --roles shape: {client?: record, realm?: list}
# --scopeMappings item shape: {client?: string, clientScope?: string, roles?: list<string>, self?: string}
# --userFederationMappers item shape: {config?: record, federationMapperType?: string, federationProviderDisplayName?: string, id?: string, name?: string}
# --userFederationProviders item shape: {changedSyncPeriod?: int, config?: record, displayName?: string, fullSyncPeriod?: int, id?: string, lastSync?: int, priority?: int, providerName?: string}
# --users item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
export def "realms-admin update" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-code-lifespan: int # format: int32
  --access-code-lifespan-login: int # format: int32
  --access-code-lifespan-user-action: int # format: int32
  --access-token-lifespan: int # format: int32
  --access-token-lifespan-for-implicit-flow: int # format: int32
  --account-theme: string
  --action-token-generated-by-admin-lifespan: int # format: int32
  --action-token-generated-by-user-lifespan: int # format: int32
  --admin-events-details-enabled: oneof<nothing, bool>
  --admin-events-enabled: oneof<nothing, bool>
  --admin-theme: string
  --attributes: record
  --authentication-flows: list # item shape: {alias?: string, authenticationExecutions?: list, builtIn?: bool, description?: string, id?: string, providerId?: string, topLevel?: bool}
  --authenticator-config: list # item shape: {alias?: string, config?: record, id?: string}
  --browser-flow: string
  --browser-security-headers: record
  --brute-force-protected: oneof<nothing, bool>
  --client-authentication-flow: string
  --client-scope-mappings: record
  --client-scopes: list # item shape: {attributes?: record, description?: string, id?: string, name?: string, protocol?: string, protocolMappers?: list}
  --client-session-idle-timeout: int # format: int32
  --client-session-max-lifespan: int # format: int32
  --clients: list # item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list<string>, defaultRoles?: list<string>, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, ... (20 more fields)}
  --components: record # shape: {empty?: bool, loadFactor?: float, threshold?: int}
  --default-default-client-scopes: list<string>
  --default-groups: list<string>
  --default-locale: string
  --default-optional-client-scopes: list<string>
  --default-roles: list<string>
  --default-signature-algorithm: string
  --direct-grant-flow: string
  --display-name: string
  --display-name-html: string
  --docker-authentication-flow: string
  --duplicate-emails-allowed: oneof<nothing, bool>
  --edit-username-allowed: oneof<nothing, bool>
  --email-theme: string
  --enabled: oneof<nothing, bool>
  --enabled-event-types: list<string>
  --events-enabled: oneof<nothing, bool>
  --events-expiration: int # format: int64
  --events-listeners: list<string>
  --failure-factor: int # format: int32
  --federated-users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
  --groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
  --id: string
  --identity-provider-mappers: list # item shape: {config?: record, id?: string, identityProviderAlias?: string, identityProviderMapper?: string, name?: string}
  --identity-providers: list # item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
  --internationalization-enabled: oneof<nothing, bool>
  --keycloak-version: string
  --login-theme: string
  --login-with-email-allowed: oneof<nothing, bool>
  --max-delta-time-seconds: int # format: int32
  --max-failure-wait-seconds: int # format: int32
  --minimum-quick-login-wait-seconds: int # format: int32
  --not-before: int # format: int32
  --offline-session-idle-timeout: int # format: int32
  --offline-session-max-lifespan: int # format: int32
  --offline-session-max-lifespan-enabled: oneof<nothing, bool>
  --otp-policy-algorithm: string
  --otp-policy-digits: int # format: int32
  --otp-policy-initial-counter: int # format: int32
  --otp-policy-look-ahead-window: int # format: int32
  --otp-policy-period: int # format: int32
  --otp-policy-type: string
  --otp-supported-applications: list<string>
  --password-policy: string
  --permanent-lockout: oneof<nothing, bool>
  --protocol-mappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
  --quick-login-check-milli-seconds: int # format: int64
  --body-realm: string
  --refresh-token-max-reuse: int # format: int32
  --registration-allowed: oneof<nothing, bool>
  --registration-email-as-username: oneof<nothing, bool>
  --registration-flow: string
  --remember-me: oneof<nothing, bool>
  --required-actions: list # item shape: {alias?: string, config?: record, defaultAction?: bool, enabled?: bool, name?: string, priority?: int, providerId?: string}
  --reset-credentials-flow: string
  --reset-password-allowed: oneof<nothing, bool>
  --revoke-refresh-token: oneof<nothing, bool>
  --roles: record # shape: {client?: record, realm?: list}
  --scope-mappings: list # item shape: {client?: string, clientScope?: string, roles?: list<string>, self?: string}
  --smtp-server: record
  --ssl-required: string
  --sso-session-idle-timeout: int # format: int32
  --sso-session-idle-timeout-remember-me: int # format: int32
  --sso-session-max-lifespan: int # format: int32
  --sso-session-max-lifespan-remember-me: int # format: int32
  --supported-locales: list<string>
  --user-federation-mappers: list # item shape: {config?: record, federationMapperType?: string, federationProviderDisplayName?: string, id?: string, name?: string}
  --user-federation-providers: list # item shape: {changedSyncPeriod?: int, config?: record, displayName?: string, fullSyncPeriod?: int, id?: string, lastSync?: int, priority?: int, providerName?: string}
  --user-managed-access-allowed: oneof<nothing, bool>
  --users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
  --verify-email: oneof<nothing, bool>
  --wait-increment-seconds: int # format: int32
  --web-authn-policy-acceptable-aaguids: list<string>
  --web-authn-policy-attestation-conveyance-preference: string
  --web-authn-policy-authenticator-attachment: string
  --web-authn-policy-avoid-same-authenticator-register: oneof<nothing, bool>
  --web-authn-policy-create-timeout: int # format: int32
  --web-authn-policy-passwordless-acceptable-aaguids: list<string>
  --web-authn-policy-passwordless-attestation-conveyance-preference: string
  --web-authn-policy-passwordless-authenticator-attachment: string
  --web-authn-policy-passwordless-avoid-same-authenticator-register: oneof<nothing, bool>
  --web-authn-policy-passwordless-create-timeout: int # format: int32
  --web-authn-policy-passwordless-require-resident-key: string
  --web-authn-policy-passwordless-rp-entity-name: string
  --web-authn-policy-passwordless-rp-id: string
  --web-authn-policy-passwordless-signature-algorithms: list<string>
  --web-authn-policy-passwordless-user-verification-requirement: string
  --web-authn-policy-require-resident-key: string
  --web-authn-policy-rp-entity-name: string
  --web-authn-policy-rp-id: string
  --web-authn-policy-signature-algorithms: list<string>
  --web-authn-policy-user-verification-requirement: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}"))
  let req_body = {"accessCodeLifespan": $access_code_lifespan, "accessCodeLifespanLogin": $access_code_lifespan_login, "accessCodeLifespanUserAction": $access_code_lifespan_user_action, "accessTokenLifespan": $access_token_lifespan, "accessTokenLifespanForImplicitFlow": $access_token_lifespan_for_implicit_flow, "accountTheme": $account_theme, "actionTokenGeneratedByAdminLifespan": $action_token_generated_by_admin_lifespan, "actionTokenGeneratedByUserLifespan": $action_token_generated_by_user_lifespan, "adminEventsDetailsEnabled": $admin_events_details_enabled, "adminEventsEnabled": $admin_events_enabled, "adminTheme": $admin_theme, "attributes": $attributes, "authenticationFlows": $authentication_flows, "authenticatorConfig": $authenticator_config, "browserFlow": $browser_flow, "browserSecurityHeaders": $browser_security_headers, "bruteForceProtected": $brute_force_protected, "clientAuthenticationFlow": $client_authentication_flow, "clientScopeMappings": $client_scope_mappings, "clientScopes": $client_scopes, "clientSessionIdleTimeout": $client_session_idle_timeout, "clientSessionMaxLifespan": $client_session_max_lifespan, "clients": $clients, "components": $components, "defaultDefaultClientScopes": $default_default_client_scopes, "defaultGroups": $default_groups, "defaultLocale": $default_locale, "defaultOptionalClientScopes": $default_optional_client_scopes, "defaultRoles": $default_roles, "defaultSignatureAlgorithm": $default_signature_algorithm, "directGrantFlow": $direct_grant_flow, "displayName": $display_name, "displayNameHtml": $display_name_html, "dockerAuthenticationFlow": $docker_authentication_flow, "duplicateEmailsAllowed": $duplicate_emails_allowed, "editUsernameAllowed": $edit_username_allowed, "emailTheme": $email_theme, "enabled": $enabled, "enabledEventTypes": $enabled_event_types, "eventsEnabled": $events_enabled, "eventsExpiration": $events_expiration, "eventsListeners": $events_listeners, "failureFactor": $failure_factor, "federatedUsers": $federated_users, "groups": $groups, "id": $id, "identityProviderMappers": $identity_provider_mappers, "identityProviders": $identity_providers, "internationalizationEnabled": $internationalization_enabled, "keycloakVersion": $keycloak_version, "loginTheme": $login_theme, "loginWithEmailAllowed": $login_with_email_allowed, "maxDeltaTimeSeconds": $max_delta_time_seconds, "maxFailureWaitSeconds": $max_failure_wait_seconds, "minimumQuickLoginWaitSeconds": $minimum_quick_login_wait_seconds, "notBefore": $not_before, "offlineSessionIdleTimeout": $offline_session_idle_timeout, "offlineSessionMaxLifespan": $offline_session_max_lifespan, "offlineSessionMaxLifespanEnabled": $offline_session_max_lifespan_enabled, "otpPolicyAlgorithm": $otp_policy_algorithm, "otpPolicyDigits": $otp_policy_digits, "otpPolicyInitialCounter": $otp_policy_initial_counter, "otpPolicyLookAheadWindow": $otp_policy_look_ahead_window, "otpPolicyPeriod": $otp_policy_period, "otpPolicyType": $otp_policy_type, "otpSupportedApplications": $otp_supported_applications, "passwordPolicy": $password_policy, "permanentLockout": $permanent_lockout, "protocolMappers": $protocol_mappers, "quickLoginCheckMilliSeconds": $quick_login_check_milli_seconds, "realm": $body_realm, "refreshTokenMaxReuse": $refresh_token_max_reuse, "registrationAllowed": $registration_allowed, "registrationEmailAsUsername": $registration_email_as_username, "registrationFlow": $registration_flow, "rememberMe": $remember_me, "requiredActions": $required_actions, "resetCredentialsFlow": $reset_credentials_flow, "resetPasswordAllowed": $reset_password_allowed, "revokeRefreshToken": $revoke_refresh_token, "roles": $roles, "scopeMappings": $scope_mappings, "smtpServer": $smtp_server, "sslRequired": $ssl_required, "ssoSessionIdleTimeout": $sso_session_idle_timeout, "ssoSessionIdleTimeoutRememberMe": $sso_session_idle_timeout_remember_me, "ssoSessionMaxLifespan": $sso_session_max_lifespan, "ssoSessionMaxLifespanRememberMe": $sso_session_max_lifespan_remember_me, "supportedLocales": $supported_locales, "userFederationMappers": $user_federation_mappers, "userFederationProviders": $user_federation_providers, "userManagedAccessAllowed": $user_managed_access_allowed, "users": $users, "verifyEmail": $verify_email, "waitIncrementSeconds": $wait_increment_seconds, "webAuthnPolicyAcceptableAaguids": $web_authn_policy_acceptable_aaguids, "webAuthnPolicyAttestationConveyancePreference": $web_authn_policy_attestation_conveyance_preference, "webAuthnPolicyAuthenticatorAttachment": $web_authn_policy_authenticator_attachment, "webAuthnPolicyAvoidSameAuthenticatorRegister": $web_authn_policy_avoid_same_authenticator_register, "webAuthnPolicyCreateTimeout": $web_authn_policy_create_timeout, "webAuthnPolicyPasswordlessAcceptableAaguids": $web_authn_policy_passwordless_acceptable_aaguids, "webAuthnPolicyPasswordlessAttestationConveyancePreference": $web_authn_policy_passwordless_attestation_conveyance_preference, "webAuthnPolicyPasswordlessAuthenticatorAttachment": $web_authn_policy_passwordless_authenticator_attachment, "webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister": $web_authn_policy_passwordless_avoid_same_authenticator_register, "webAuthnPolicyPasswordlessCreateTimeout": $web_authn_policy_passwordless_create_timeout, "webAuthnPolicyPasswordlessRequireResidentKey": $web_authn_policy_passwordless_require_resident_key, "webAuthnPolicyPasswordlessRpEntityName": $web_authn_policy_passwordless_rp_entity_name, "webAuthnPolicyPasswordlessRpId": $web_authn_policy_passwordless_rp_id, "webAuthnPolicyPasswordlessSignatureAlgorithms": $web_authn_policy_passwordless_signature_algorithms, "webAuthnPolicyPasswordlessUserVerificationRequirement": $web_authn_policy_passwordless_user_verification_requirement, "webAuthnPolicyRequireResidentKey": $web_authn_policy_require_resident_key, "webAuthnPolicyRpEntityName": $web_authn_policy_rp_entity_name, "webAuthnPolicyRpId": $web_authn_policy_rp_id, "webAuthnPolicySignatureAlgorithms": $web_authn_policy_signature_algorithms, "webAuthnPolicyUserVerificationRequirement": $web_authn_policy_user_verification_requirement} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/admin-events"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get admin events Returns all admin events, or filters events based on URL query parameters listed here
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-client: string
  --auth-ip-address: string
  --auth-realm: string
  --auth-user: string # user id
  --date-from: string
  --date-to: string
  --first: int # format: int32
  --max: int # Maximum results size (defaults to 100) (format: int32)
  --operation-types: list<string>
  --resource-path: string
  --resource-types: list<string>
]: nothing -> table<authDetails: record<clientId: string, ipAddress: string, realmId: string, userId: string>, error: string, operationType: string, realmId: string, representation: string, resourcePath: string, resourceType: string, time: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let qp = [(serialize-qp "authClient" $auth_client "scalar") (serialize-qp "authIpAddress" $auth_ip_address "scalar") (serialize-qp "authRealm" $auth_realm "scalar") (serialize-qp "authUser" $auth_user "scalar") (serialize-qp "dateFrom" $date_from "scalar") (serialize-qp "dateTo" $date_to "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "operationTypes" $operation_types "multi") (serialize-qp "resourcePath" $resource_path "scalar") (serialize-qp "resourceTypes" $resource_types "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/admin-events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"authClient": $auth_client, "authIpAddress": $auth_ip_address, "authRealm": $auth_realm, "authUser": $auth_user, "dateFrom": $date_from, "dateTo": $date_to, "first": $first, "max": $max, "operationTypes": $operation_types, "resourcePath": $resource_path, "resourceTypes": $resource_types} | compact), body: null}
}

# Clear any user login failures for all users This can release temporary disabled users
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/attack-detection/brute-force/users"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Clear any user login failures for the user This can release temporary disabled user
#
# DELETE /{realm}/attack-detection/brute-force/users/{userId}
export def "attack-detection-brute-force-users delete-by-realm-user-id" [
  realm: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), user_id: (encode-path-segment $user_id)} | format pattern "/{realm}/attack-detection/brute-force/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get status of a username in brute force detection
#
# GET /{realm}/attack-detection/brute-force/users/{userId}
export def "attack-detection-brute-force-users get" [
  realm: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), user_id: (encode-path-segment $user_id)} | format pattern "/{realm}/attack-detection/brute-force/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get authenticator providers Returns a list of authenticator providers.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/authentication/authenticator-providers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get client authenticator providers Returns a list of client authenticator providers.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/authentication/client-authenticator-providers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get authenticator provider’s configuration description
#
# GET /{realm}/authentication/config-description/{providerId}
export def "authentication-config-description get" [
  realm: string
  provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<helpText: string, name: string, properties: table<defaultValue: record, helpText: string, label: string, name: string, options: list, secret: bool, type: string>, providerId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($provider_id | is-empty) { error make --unspanned { msg: "path parameter 'providerId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), provider_id: (encode-path-segment $provider_id)} | format pattern "/{realm}/authentication/config-description/{provider_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/authentication/config/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alias: string, config: record, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/authentication/config/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update authenticator configuration
#
# PUT /{realm}/authentication/config/{id}
export def "authentication-config update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --config: record
  --body-id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/authentication/config/{id}"))
  let req_body = {"alias": $alias, "config": $config, "id": $body_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add new authentication execution
#
# POST /{realm}/authentication/executions
export def "authentication-executions create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authenticator: string
  --authenticator-config: string
  --authenticator-flow: oneof<nothing, bool>
  --autheticator-flow: oneof<nothing, bool>
  --flow-id: string
  --id: string
  --parent-flow: string
  --priority: int # format: int32
  --requirement: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/authentication/executions"))
  let req_body = {"authenticator": $authenticator, "authenticatorConfig": $authenticator_config, "authenticatorFlow": $authenticator_flow, "autheticatorFlow": $autheticator_flow, "flowId": $flow_id, "id": $id, "parentFlow": $parent_flow, "priority": $priority, "requirement": $requirement} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete execution
#
# DELETE /{realm}/authentication/executions/{executionId}
export def "authentication-executions delete" [
  realm: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($execution_id | is-empty) { error make --unspanned { msg: "path parameter 'executionId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), execution_id: (encode-path-segment $execution_id)} | format pattern "/{realm}/authentication/executions/{execution_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Single Execution
#
# GET /{realm}/authentication/executions/{executionId}
export def "authentication-executions get" [
  realm: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($execution_id | is-empty) { error make --unspanned { msg: "path parameter 'executionId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), execution_id: (encode-path-segment $execution_id)} | format pattern "/{realm}/authentication/executions/{execution_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update execution with new configuration
#
# POST /{realm}/authentication/executions/{executionId}/config
export def "authentication-executions-config create" [
  realm: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --config: record
  --id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($execution_id | is-empty) { error make --unspanned { msg: "path parameter 'executionId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), execution_id: (encode-path-segment $execution_id)} | format pattern "/{realm}/authentication/executions/{execution_id}/config"))
  let req_body = {"alias": $alias, "config": $config, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lower execution’s priority
#
# POST /{realm}/authentication/executions/{executionId}/lower-priority
export def "authentication-executions-lower-priority create" [
  realm: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($execution_id | is-empty) { error make --unspanned { msg: "path parameter 'executionId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), execution_id: (encode-path-segment $execution_id)} | format pattern "/{realm}/authentication/executions/{execution_id}/lower-priority"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Raise execution’s priority
#
# POST /{realm}/authentication/executions/{executionId}/raise-priority
export def "authentication-executions-raise-priority create" [
  realm: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($execution_id | is-empty) { error make --unspanned { msg: "path parameter 'executionId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), execution_id: (encode-path-segment $execution_id)} | format pattern "/{realm}/authentication/executions/{execution_id}/raise-priority"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get authentication flows Returns a list of authentication flows.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<alias: string, authenticationExecutions: list<record>, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/authentication/flows"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new authentication flow
#
# POST /{realm}/authentication/flows
# --authenticationExecutions item shape: {authenticator?: string, authenticatorConfig?: string, authenticatorFlow?: bool, autheticatorFlow?: bool, flowAlias?: string, priority?: int, requirement?: string, userSetupAllowed?: bool}
export def "authentication-flows create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --authentication-executions: list # item shape: {authenticator?: string, authenticatorConfig?: string, authenticatorFlow?: bool, autheticatorFlow?: bool, flowAlias?: string, priority?: int, requirement?: string, userSetupAllowed?: bool}
  --built-in: oneof<nothing, bool>
  --description: string
  --id: string
  --provider-id: string
  --top-level: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/authentication/flows"))
  let req_body = {"alias": $alias, "authenticationExecutions": $authentication_executions, "builtIn": $built_in, "description": $description, "id": $id, "providerId": $provider_id, "topLevel": $top_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Copy existing authentication flow under a new name The new name is given as 'newName' attribute of the passed JSON object
#
# POST /{realm}/authentication/flows/{flowAlias}/copy
export def "authentication-flows-copy create" [
  realm: string
  flow_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($flow_alias | is-empty) { error make --unspanned { msg: "path parameter 'flowAlias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), flow_alias: (encode-path-segment $flow_alias)} | format pattern "/{realm}/authentication/flows/{flow_alias}/copy"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get authentication executions for a flow
#
# GET /{realm}/authentication/flows/{flowAlias}/executions
export def "authentication-flows-executions get" [
  realm: string
  flow_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($flow_alias | is-empty) { error make --unspanned { msg: "path parameter 'flowAlias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), flow_alias: (encode-path-segment $flow_alias)} | format pattern "/{realm}/authentication/flows/{flow_alias}/executions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update authentication executions of a flow
#
# PUT /{realm}/authentication/flows/{flowAlias}/executions
export def "authentication-flows-executions update" [
  realm: string
  flow_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --authentication-config: string
  --authentication-flow: oneof<nothing, bool>
  --configurable: oneof<nothing, bool>
  --display-name: string
  --flow-id: string
  --id: string
  --index: int # format: int32
  --level: int # format: int32
  --provider-id: string
  --requirement: string
  --requirement-choices: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($flow_alias | is-empty) { error make --unspanned { msg: "path parameter 'flowAlias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), flow_alias: (encode-path-segment $flow_alias)} | format pattern "/{realm}/authentication/flows/{flow_alias}/executions"))
  let req_body = {"alias": $alias, "authenticationConfig": $authentication_config, "authenticationFlow": $authentication_flow, "configurable": $configurable, "displayName": $display_name, "flowId": $flow_id, "id": $id, "index": $index, "level": $level, "providerId": $provider_id, "requirement": $requirement, "requirementChoices": $requirement_choices} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add new authentication execution to a flow
#
# POST /{realm}/authentication/flows/{flowAlias}/executions/execution
export def "authentication-flows-executions-execution create" [
  realm: string
  flow_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($flow_alias | is-empty) { error make --unspanned { msg: "path parameter 'flowAlias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), flow_alias: (encode-path-segment $flow_alias)} | format pattern "/{realm}/authentication/flows/{flow_alias}/executions/execution"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Add new flow with new execution to existing flow
#
# POST /{realm}/authentication/flows/{flowAlias}/executions/flow
export def "authentication-flows-executions-flow create" [
  realm: string
  flow_alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($flow_alias | is-empty) { error make --unspanned { msg: "path parameter 'flowAlias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), flow_alias: (encode-path-segment $flow_alias)} | format pattern "/{realm}/authentication/flows/{flow_alias}/executions/flow"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/authentication/flows/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alias: string, authenticationExecutions: table<authenticator: string, authenticatorConfig: string, authenticatorFlow: bool, autheticatorFlow: bool, flowAlias: string, priority: int, requirement: string, userSetupAllowed: bool>, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/authentication/flows/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an authentication flow
#
# PUT /{realm}/authentication/flows/{id}
# --authenticationExecutions item shape: {authenticator?: string, authenticatorConfig?: string, authenticatorFlow?: bool, autheticatorFlow?: bool, flowAlias?: string, priority?: int, requirement?: string, userSetupAllowed?: bool}
export def "authentication-flows update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --alias: string
  --authentication-executions: list # item shape: {authenticator?: string, authenticatorConfig?: string, authenticatorFlow?: bool, autheticatorFlow?: bool, flowAlias?: string, priority?: int, requirement?: string, userSetupAllowed?: bool}
  --built-in: oneof<nothing, bool>
  --description: string
  --body-id: string
  --provider-id: string
  --top-level: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/authentication/flows/{id}"))
  let req_body = {"alias": $alias, "authenticationExecutions": $authentication_executions, "builtIn": $built_in, "description": $description, "id": $body_id, "providerId": $provider_id, "topLevel": $top_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get form action providers Returns a list of form action providers.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/authentication/form-action-providers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get form providers Returns a list of form providers.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/authentication/form-providers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/authentication/per-client-config-description"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Register a new required actions
#
# POST /{realm}/authentication/register-required-action
export def "authentication-register-required-action create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/authentication/register-required-action"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get required actions Returns a list of required actions.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/authentication/required-actions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/authentication/required-actions/{alias}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/authentication/required-actions/{alias}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update required action
#
# PUT /{realm}/authentication/required-actions/{alias}
export def "authentication-required-actions update" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-alias: string
  --config: record
  --default-action: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --name: string
  --priority: int # format: int32
  --provider-id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/authentication/required-actions/{alias}"))
  let req_body = {"alias": $body_alias, "config": $config, "defaultAction": $default_action, "enabled": $enabled, "name": $name, "priority": $priority, "providerId": $provider_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lower required action’s priority
#
# POST /{realm}/authentication/required-actions/{alias}/lower-priority
export def "authentication-required-actions-lower-priority create" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/authentication/required-actions/{alias}/lower-priority"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Raise required action’s priority
#
# POST /{realm}/authentication/required-actions/{alias}/raise-priority
export def "authentication-required-actions-raise-priority create" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/authentication/required-actions/{alias}/raise-priority"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get unregistered required actions Returns a list of unregistered required actions.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/authentication/unregistered-required-actions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Clear cache of external public keys (Public keys of clients or Identity providers)
#
# POST /{realm}/clear-keys-cache
export def "clear-keys-cache create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/clear-keys-cache"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Clear realm cache
#
# POST /{realm}/clear-realm-cache
export def "clear-realm-cache create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/clear-realm-cache"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Clear user cache
#
# POST /{realm}/clear-user-cache
export def "clear-user-cache create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/clear-user-cache"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Base path for importing clients under this realm.
#
# POST /{realm}/client-description-converter
export def "client-description-converter create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> record<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list<record>, policyEnforcementMode: string, resources: list<record>, scopes: list<record>>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/client-description-converter"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/plain" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<helpText: string, id: string, metadata: record, properties: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/client-registration-policy/providers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get client scopes belonging to the realm Returns a list of client scopes belonging to the realm
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/client-scopes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new client scope Client Scope’s name must be unique!
#
# POST /{realm}/client-scopes
# --protocolMappers item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
export def "client-scopes create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --description: string
  --id: string
  --name: string
  --protocol: string
  --protocol-mappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/client-scopes"))
  let req_body = {"attributes": $attributes, "description": $description, "id": $id, "name": $name, "protocol": $protocol, "protocolMappers": $protocol_mappers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id1 | is-empty) { error make --unspanned { msg: "path parameter 'id1' must be non-empty" } }
  if ($id2 | is-empty) { error make --unspanned { msg: "path parameter 'id2' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id1: (encode-path-segment $id1), id2: (encode-path-segment $id2)} | format pattern "/{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config: record, id: string, name: string, protocol: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id1 | is-empty) { error make --unspanned { msg: "path parameter 'id1' must be non-empty" } }
  if ($id2 | is-empty) { error make --unspanned { msg: "path parameter 'id2' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id1: (encode-path-segment $id1), id2: (encode-path-segment $id2)} | format pattern "/{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the mapper
#
# PUT /{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}
export def "client-scopes-protocol-mappers-models update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --id: string
  --name: string
  --protocol: string
  --protocol-mapper: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id1 | is-empty) { error make --unspanned { msg: "path parameter 'id1' must be non-empty" } }
  if ($id2 | is-empty) { error make --unspanned { msg: "path parameter 'id2' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id1: (encode-path-segment $id1), id2: (encode-path-segment $id2)} | format pattern "/{realm}/client-scopes/{id1}/protocol-mappers/models/{id2}"))
  let req_body = {"config": $config, "id": $id, "name": $name, "protocol": $protocol, "protocolMapper": $protocol_mapper} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/client-scopes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/client-scopes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the client scope
#
# PUT /{realm}/client-scopes/{id}
# --protocolMappers item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
export def "client-scopes update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --description: string
  --body-id: string
  --name: string
  --protocol: string
  --protocol-mappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/client-scopes/{id}"))
  let req_body = {"attributes": $attributes, "description": $description, "id": $body_id, "name": $name, "protocol": $protocol, "protocolMappers": $protocol_mappers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create multiple mappers
#
# POST /{realm}/client-scopes/{id}/protocol-mappers/add-models
export def "client-scopes-protocol-mappers-add-models create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/client-scopes/{id}/protocol-mappers/add-models"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<config: record, id: string, name: string, protocol: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/client-scopes/{id}/protocol-mappers/models"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a mapper
#
# POST /{realm}/client-scopes/{id}/protocol-mappers/models
export def "client-scopes-protocol-mappers-models create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --body-id: string
  --name: string
  --protocol: string
  --protocol-mapper: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/client-scopes/{id}/protocol-mappers/models"))
  let req_body = {"config": $config, "id": $body_id, "name": $name, "protocol": $protocol, "protocolMapper": $protocol_mapper} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<config: record, id: string, name: string, protocol: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($protocol | is-empty) { error make --unspanned { msg: "path parameter 'protocol' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), protocol: (encode-path-segment $protocol)} | format pattern "/{realm}/client-scopes/{id}/protocol-mappers/protocol/{protocol}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/client-scopes/{id}/scope-mappings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/client-scopes/{id}/scope-mappings/clients/{client}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the roles associated with a client’s scope Returns roles for the client.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/client-scopes/{id}/scope-mappings/clients/{client}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add client-level roles to the client’s scope
#
# POST /{realm}/client-scopes/{id}/scope-mappings/clients/{client}
export def "client-scopes-scope-mappings-clients create" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/client-scopes/{id}/scope-mappings/clients/{client}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The available client-level roles Returns the roles for the client that can be associated with the client’s scope
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/client-scopes/{id}/scope-mappings/clients/{client}/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get effective client roles Returns the roles for the client that are associated with the client’s scope.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/client-scopes/{id}/scope-mappings/clients/{client}/composite"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/client-scopes/{id}/scope-mappings/realm"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/client-scopes/{id}/scope-mappings/realm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a set of realm-level roles to the client’s scope
#
# POST /{realm}/client-scopes/{id}/scope-mappings/realm
export def "client-scopes-scope-mappings-realm create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/client-scopes/{id}/scope-mappings/realm"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/client-scopes/{id}/scope-mappings/realm/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get effective realm-level roles associated with the client’s scope What this does is recurse any composite roles associated with the client’s scope and adds the roles to this lists.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/client-scopes/{id}/scope-mappings/realm/composite"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get client session stats Returns a JSON map.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/client-session-stats"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get clients belonging to the realm Returns a list of clients belonging to the realm
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # filter by clientId
  --first: int # the first result (format: int32)
  --max: int # the max results to return (format: int32)
  --search: oneof<nothing, bool> # whether this is a search query or a getClientById query
  --viewable-only: oneof<nothing, bool> # filter clients that cannot be viewed in full by admin
]: nothing -> table<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list, policyEnforcementMode: string, resources: list, scopes: list>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: list<record>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "viewableOnly" $viewable_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/clients") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"clientId": $client_id, "first": $first, "max": $max, "search": $search, "viewableOnly": $viewable_only} | compact), body: null}
}

# Create a new client Client’s client_id must be unique!
#
# POST /{realm}/clients
# --authorizationSettings shape: {allowRemoteResourceManagement?: bool, clientId?: string, decisionStrategy?: "AFFIRMATIVE"|"UNANIMOUS"|"CONSENSUS", id?: string, name?: string, policies?: list, policyEnforcementMode?: "ENFORCING"|"PERMISSIVE"|"DISABLED", resources?: list, scopes?: list}
# --protocolMappers item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
export def "clients create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --admin-url: string
  --always-display-in-console: oneof<nothing, bool>
  --attributes: record
  --authentication-flow-binding-overrides: record
  --authorization-services-enabled: oneof<nothing, bool>
  --authorization-settings: record # shape: {allowRemoteResourceManagement?: bool, clientId?: string, decisionStrategy?: "AFFIRMATIVE"|"UNANIMOUS"|"CONSENSUS", id?: string, name?: string, policies?: list, policyEnforcementMode?: "ENFORCING"|"PERMISSIVE"|"DISABLED", resources?: list, scopes?: list}
  --body-base-url: string
  --bearer-only: oneof<nothing, bool>
  --client-authenticator-type: string
  --client-id: string
  --consent-required: oneof<nothing, bool>
  --default-client-scopes: list<string>
  --default-roles: list<string>
  --description: string
  --direct-access-grants-enabled: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --frontchannel-logout: oneof<nothing, bool>
  --full-scope-allowed: oneof<nothing, bool>
  --id: string
  --implicit-flow-enabled: oneof<nothing, bool>
  --name: string
  --node-re-registration-timeout: int # format: int32
  --not-before: int # format: int32
  --optional-client-scopes: list<string>
  --origin: string
  --protocol: string
  --protocol-mappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
  --public-client: oneof<nothing, bool>
  --redirect-uris: list<string>
  --registered-nodes: record
  --registration-access-token: string
  --root-url: string
  --secret: string
  --service-accounts-enabled: oneof<nothing, bool>
  --standard-flow-enabled: oneof<nothing, bool>
  --surrogate-auth-required: oneof<nothing, bool>
  --web-origins: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/clients"))
  let req_body = {"access": $access, "adminUrl": $admin_url, "alwaysDisplayInConsole": $always_display_in_console, "attributes": $attributes, "authenticationFlowBindingOverrides": $authentication_flow_binding_overrides, "authorizationServicesEnabled": $authorization_services_enabled, "authorizationSettings": $authorization_settings, "baseUrl": $body_base_url, "bearerOnly": $bearer_only, "clientAuthenticatorType": $client_authenticator_type, "clientId": $client_id, "consentRequired": $consent_required, "defaultClientScopes": $default_client_scopes, "defaultRoles": $default_roles, "description": $description, "directAccessGrantsEnabled": $direct_access_grants_enabled, "enabled": $enabled, "frontchannelLogout": $frontchannel_logout, "fullScopeAllowed": $full_scope_allowed, "id": $id, "implicitFlowEnabled": $implicit_flow_enabled, "name": $name, "nodeReRegistrationTimeout": $node_re_registration_timeout, "notBefore": $not_before, "optionalClientScopes": $optional_client_scopes, "origin": $origin, "protocol": $protocol, "protocolMappers": $protocol_mappers, "publicClient": $public_client, "redirectUris": $redirect_uris, "registeredNodes": $registered_nodes, "registrationAccessToken": $registration_access_token, "rootUrl": $root_url, "secret": $secret, "serviceAccountsEnabled": $service_accounts_enabled, "standardFlowEnabled": $standard_flow_enabled, "surrogateAuthRequired": $surrogate_auth_required, "webOrigins": $web_origins} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<count: int, expiration: int, id: string, remainingCount: int, timestamp: int, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/clients-initial-access"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new initial access token.
#
# POST /{realm}/clients-initial-access
export def "clients-initial-access create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # format: int32
  --expiration: int # format: int32
]: any -> record<count: int, expiration: int, id: string, remainingCount: int, timestamp: int, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/clients-initial-access"))
  let req_body = {"count": $count, "expiration": $expiration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients-initial-access/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id1 | is-empty) { error make --unspanned { msg: "path parameter 'id1' must be non-empty" } }
  if ($id2 | is-empty) { error make --unspanned { msg: "path parameter 'id2' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id1: (encode-path-segment $id1), id2: (encode-path-segment $id2)} | format pattern "/{realm}/clients/{id1}/protocol-mappers/models/{id2}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config: record, id: string, name: string, protocol: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id1 | is-empty) { error make --unspanned { msg: "path parameter 'id1' must be non-empty" } }
  if ($id2 | is-empty) { error make --unspanned { msg: "path parameter 'id2' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id1: (encode-path-segment $id1), id2: (encode-path-segment $id2)} | format pattern "/{realm}/clients/{id1}/protocol-mappers/models/{id2}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the mapper
#
# PUT /{realm}/clients/{id1}/protocol-mappers/models/{id2}
export def "clients-protocol-mappers-models update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --id: string
  --name: string
  --protocol: string
  --protocol-mapper: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id1 | is-empty) { error make --unspanned { msg: "path parameter 'id1' must be non-empty" } }
  if ($id2 | is-empty) { error make --unspanned { msg: "path parameter 'id2' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id1: (encode-path-segment $id1), id2: (encode-path-segment $id2)} | format pattern "/{realm}/clients/{id1}/protocol-mappers/models/{id2}"))
  let req_body = {"config": $config, "id": $id, "name": $name, "protocol": $protocol, "protocolMapper": $protocol_mapper} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list<record>, policyEnforcementMode: string, resources: list<record>, scopes: list<record>>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the client
#
# PUT /{realm}/clients/{id}
# --authorizationSettings shape: {allowRemoteResourceManagement?: bool, clientId?: string, decisionStrategy?: "AFFIRMATIVE"|"UNANIMOUS"|"CONSENSUS", id?: string, name?: string, policies?: list, policyEnforcementMode?: "ENFORCING"|"PERMISSIVE"|"DISABLED", resources?: list, scopes?: list}
# --protocolMappers item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
export def "clients update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --admin-url: string
  --always-display-in-console: oneof<nothing, bool>
  --attributes: record
  --authentication-flow-binding-overrides: record
  --authorization-services-enabled: oneof<nothing, bool>
  --authorization-settings: record # shape: {allowRemoteResourceManagement?: bool, clientId?: string, decisionStrategy?: "AFFIRMATIVE"|"UNANIMOUS"|"CONSENSUS", id?: string, name?: string, policies?: list, policyEnforcementMode?: "ENFORCING"|"PERMISSIVE"|"DISABLED", resources?: list, scopes?: list}
  --body-base-url: string
  --bearer-only: oneof<nothing, bool>
  --client-authenticator-type: string
  --client-id: string
  --consent-required: oneof<nothing, bool>
  --default-client-scopes: list<string>
  --default-roles: list<string>
  --description: string
  --direct-access-grants-enabled: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --frontchannel-logout: oneof<nothing, bool>
  --full-scope-allowed: oneof<nothing, bool>
  --body-id: string
  --implicit-flow-enabled: oneof<nothing, bool>
  --name: string
  --node-re-registration-timeout: int # format: int32
  --not-before: int # format: int32
  --optional-client-scopes: list<string>
  --origin: string
  --protocol: string
  --protocol-mappers: list # item shape: {config?: record, id?: string, name?: string, protocol?: string, protocolMapper?: string}
  --public-client: oneof<nothing, bool>
  --redirect-uris: list<string>
  --registered-nodes: record
  --registration-access-token: string
  --root-url: string
  --secret: string
  --service-accounts-enabled: oneof<nothing, bool>
  --standard-flow-enabled: oneof<nothing, bool>
  --surrogate-auth-required: oneof<nothing, bool>
  --web-origins: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}"))
  let req_body = {"access": $access, "adminUrl": $admin_url, "alwaysDisplayInConsole": $always_display_in_console, "attributes": $attributes, "authenticationFlowBindingOverrides": $authentication_flow_binding_overrides, "authorizationServicesEnabled": $authorization_services_enabled, "authorizationSettings": $authorization_settings, "baseUrl": $body_base_url, "bearerOnly": $bearer_only, "clientAuthenticatorType": $client_authenticator_type, "clientId": $client_id, "consentRequired": $consent_required, "defaultClientScopes": $default_client_scopes, "defaultRoles": $default_roles, "description": $description, "directAccessGrantsEnabled": $direct_access_grants_enabled, "enabled": $enabled, "frontchannelLogout": $frontchannel_logout, "fullScopeAllowed": $full_scope_allowed, "id": $body_id, "implicitFlowEnabled": $implicit_flow_enabled, "name": $name, "nodeReRegistrationTimeout": $node_re_registration_timeout, "notBefore": $not_before, "optionalClientScopes": $optional_client_scopes, "origin": $origin, "protocol": $protocol, "protocolMappers": $protocol_mappers, "publicClient": $public_client, "redirectUris": $redirect_uris, "registeredNodes": $registered_nodes, "registrationAccessToken": $registration_access_token, "rootUrl": $root_url, "secret": $secret, "serviceAccountsEnabled": $service_accounts_enabled, "standardFlowEnabled": $standard_flow_enabled, "surrogateAuthRequired": $surrogate_auth_required, "webOrigins": $web_origins} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificate: string, kid: string, privateKey: string, publicKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attr | is-empty) { error make --unspanned { msg: "path parameter 'attr' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), attr: (encode-path-segment $attr)} | format pattern "/{realm}/clients/{id}/certificates/{attr}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a keystore file for the client, containing private key and public certificate
#
# POST /{realm}/clients/{id}/certificates/{attr}/download
export def "clients-certificates-download create" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string
  --key-alias: string
  --key-password: string
  --realm-alias: string
  --realm-certificate: oneof<nothing, bool>
  --store-password: string
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attr | is-empty) { error make --unspanned { msg: "path parameter 'attr' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), attr: (encode-path-segment $attr)} | format pattern "/{realm}/clients/{id}/certificates/{attr}/download"))
  let req_body = {"format": $format, "keyAlias": $key_alias, "keyPassword": $key_password, "realmAlias": $realm_alias, "realmCertificate": $realm_certificate, "storePassword": $store_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate a new certificate with new key pair
#
# POST /{realm}/clients/{id}/certificates/{attr}/generate
export def "clients-certificates-generate create" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificate: string, kid: string, privateKey: string, publicKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attr | is-empty) { error make --unspanned { msg: "path parameter 'attr' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), attr: (encode-path-segment $attr)} | format pattern "/{realm}/clients/{id}/certificates/{attr}/generate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate a new keypair and certificate, and get the private key file Generates a keypair and certificate and serves the private key in a specified keystore format.
#
# POST /{realm}/clients/{id}/certificates/{attr}/generate-and-download
export def "clients-certificates-generate-and-download create" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string
  --key-alias: string
  --key-password: string
  --realm-alias: string
  --realm-certificate: oneof<nothing, bool>
  --store-password: string
]: any -> oneof<string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attr | is-empty) { error make --unspanned { msg: "path parameter 'attr' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), attr: (encode-path-segment $attr)} | format pattern "/{realm}/clients/{id}/certificates/{attr}/generate-and-download"))
  let req_body = {"format": $format, "keyAlias": $key_alias, "keyPassword": $key_password, "realmAlias": $realm_alias, "realmCertificate": $realm_certificate, "storePassword": $store_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Upload certificate and eventually private key
#
# POST /{realm}/clients/{id}/certificates/{attr}/upload
export def "clients-certificates-upload create" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificate: string, kid: string, privateKey: string, publicKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attr | is-empty) { error make --unspanned { msg: "path parameter 'attr' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), attr: (encode-path-segment $attr)} | format pattern "/{realm}/clients/{id}/certificates/{attr}/upload"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload only certificate, not private key
#
# POST /{realm}/clients/{id}/certificates/{attr}/upload-certificate
export def "clients-certificates-upload-certificate create" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<certificate: string, kid: string, privateKey: string, publicKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($attr | is-empty) { error make --unspanned { msg: "path parameter 'attr' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), attr: (encode-path-segment $attr)} | format pattern "/{realm}/clients/{id}/certificates/{attr}/upload-certificate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/client-secret"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate a new secret for the client
#
# POST /{realm}/clients/{id}/client-secret
export def "clients-client-secret create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/client-secret"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/default-client-scopes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE /{realm}/clients/{id}/default-client-scopes/{clientScopeId}
export def "clients-default-client-scopes delete" [
  realm: string
  id: string
  client_scope_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client_scope_id | is-empty) { error make --unspanned { msg: "path parameter 'clientScopeId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client_scope_id: (encode-path-segment $client_scope_id)} | format pattern "/{realm}/clients/{id}/default-client-scopes/{client_scope_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /{realm}/clients/{id}/default-client-scopes/{clientScopeId}
export def "clients-default-client-scopes update" [
  realm: string
  id: string
  client_scope_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client_scope_id | is-empty) { error make --unspanned { msg: "path parameter 'clientScopeId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client_scope_id: (encode-path-segment $client_scope_id)} | format pattern "/{realm}/clients/{id}/default-client-scopes/{client_scope_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
  --user-id: string
]: nothing -> record<acr: string, address: record<country: string, formatted: string, locality: string, postal_code: string, region: string, street_address: string>, allowed_origins: list<string>, at_hash: string, auth_time: int, authorization: record<permissions: list<record>>, azp: string, birthdate: string, c_hash: string, category: string, claims_locales: string, cnf: record<x5t_S256: string>, email: string, email_verified: bool, exp: int, family_name: string, gender: string, given_name: string, iat: int, iss: string, jti: string, locale: string, middle_name: string, name: string, nbf: int, nickname: string, nonce: string, otherClaims: record, phone_number: string, phone_number_verified: bool, picture: string, preferred_username: string, profile: string, realm_access: record<roles: list<string>, verify_caller: bool>, s_hash: string, scope: string, session_state: string, sub: string, trusted_certs: list<string>, typ: string, updated_at: int, website: string, zoneinfo: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "userId" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/evaluate-scopes/generate-example-access-token") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"scope": $scope, "userId": $user_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
]: nothing -> table<containerId: string, containerName: string, containerType: string, mapperId: string, mapperName: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/evaluate-scopes/protocol-mappers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"scope": $scope} | compact), body: null}
}

# Get effective scope mapping of all roles of particular role container, which this client is defacto allowed to have in the accessToken issued for him.
#
# GET /{realm}/clients/{id}/evaluate-scopes/scope-mappings/{roleContainerId}/granted
export def "clients-evaluate-scopes-scope-mappings-granted get" [
  realm: string
  id: string
  role_container_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_container_id | is-empty) { error make --unspanned { msg: "path parameter 'roleContainerId' must be non-empty" } }
  let qp = [(serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_container_id: (encode-path-segment $role_container_id)} | format pattern "/{realm}/clients/{id}/evaluate-scopes/scope-mappings/{role_container_id}/granted") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"scope": $scope} | compact), body: null}
}

# Get roles, which this client doesn’t have scope for and can’t have them in the accessToken issued for him.
#
# GET /{realm}/clients/{id}/evaluate-scopes/scope-mappings/{roleContainerId}/not-granted
export def "clients-evaluate-scopes-scope-mappings-not-granted get" [
  realm: string
  id: string
  role_container_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_container_id | is-empty) { error make --unspanned { msg: "path parameter 'roleContainerId' must be non-empty" } }
  let qp = [(serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_container_id: (encode-path-segment $role_container_id)} | format pattern "/{realm}/clients/{id}/evaluate-scopes/scope-mappings/{role_container_id}/not-granted") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"scope": $scope} | compact), body: null}
}

# GET /{realm}/clients/{id}/installation/providers/{providerId}
export def "clients-installation-providers get" [
  realm: string
  id: string
  provider_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($provider_id | is-empty) { error make --unspanned { msg: "path parameter 'providerId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), provider_id: (encode-path-segment $provider_id)} | format pattern "/{realm}/clients/{id}/installation/providers/{provider_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/management/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# PUT /{realm}/clients/{id}/management/permissions
export def "clients-management-permissions update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/management/permissions"))
  let req_body = {"enabled": $enabled, "resource": $resource, "scopePermissions": $scope_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Register a cluster node with the client Manually register cluster node to this client - usually it’s not needed to call this directly as adapter should handle by sending registration request to Keycloak
#
# POST /{realm}/clients/{id}/nodes
export def "clients-nodes create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/nodes"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($node | is-empty) { error make --unspanned { msg: "path parameter 'node' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), node: (encode-path-segment $node)} | format pattern "/{realm}/clients/{id}/nodes/{node}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get application offline session count Returns a number of offline user sessions associated with this client { "count": number }
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/offline-session-count"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get offline sessions for client Returns a list of offline user sessions associated with this client
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first: int # Paging offset (format: int32)
  --max: int # Maximum results size (defaults to 100) (format: int32)
]: nothing -> table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/offline-sessions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"first": $first, "max": $max} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/optional-client-scopes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE /{realm}/clients/{id}/optional-client-scopes/{clientScopeId}
export def "clients-optional-client-scopes delete" [
  realm: string
  id: string
  client_scope_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client_scope_id | is-empty) { error make --unspanned { msg: "path parameter 'clientScopeId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client_scope_id: (encode-path-segment $client_scope_id)} | format pattern "/{realm}/clients/{id}/optional-client-scopes/{client_scope_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /{realm}/clients/{id}/optional-client-scopes/{clientScopeId}
export def "clients-optional-client-scopes update" [
  realm: string
  id: string
  client_scope_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client_scope_id | is-empty) { error make --unspanned { msg: "path parameter 'clientScopeId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client_scope_id: (encode-path-segment $client_scope_id)} | format pattern "/{realm}/clients/{id}/optional-client-scopes/{client_scope_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create multiple mappers
#
# POST /{realm}/clients/{id}/protocol-mappers/add-models
export def "clients-protocol-mappers-add-models create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/protocol-mappers/add-models"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<config: record, id: string, name: string, protocol: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/protocol-mappers/models"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a mapper
#
# POST /{realm}/clients/{id}/protocol-mappers/models
export def "clients-protocol-mappers-models create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --body-id: string
  --name: string
  --protocol: string
  --protocol-mapper: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/protocol-mappers/models"))
  let req_body = {"config": $config, "id": $body_id, "name": $name, "protocol": $protocol, "protocolMapper": $protocol_mapper} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<config: record, id: string, name: string, protocol: string, protocolMapper: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($protocol | is-empty) { error make --unspanned { msg: "path parameter 'protocol' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), protocol: (encode-path-segment $protocol)} | format pattern "/{realm}/clients/{id}/protocol-mappers/protocol/{protocol}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Push the client’s revocation policy to its admin URL If the client has an admin URL, push revocation policy to it.
#
# POST /{realm}/clients/{id}/push-revocation
export def "clients-push-revocation create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<failedRequests: list<string>, successRequests: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/push-revocation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate a new registration access token for the client
#
# POST /{realm}/clients/{id}/registration-access-token
export def "clients-registration-access-token create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record<allowRemoteResourceManagement: bool, clientId: string, decisionStrategy: string, id: string, name: string, policies: list<record>, policyEnforcementMode: string, resources: list<record>, scopes: list<record>>, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list<string>, defaultRoles: list<string>, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list<string>, origin: string, protocol: string, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, publicClient: bool, redirectUris: list<string>, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/registration-access-token"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool>
  --first: int # format: int32
  --max: int # format: int32
  --search: string
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "briefRepresentation" $brief_representation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/roles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"briefRepresentation": $brief_representation, "first": $first, "max": $max, "search": $search} | compact), body: null}
}

# Create a new role for the realm or client
#
# POST /{realm}/clients/{id}/roles
# --composites shape: {client?: record, realm?: list<string>}
export def "clients-roles create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --client-role: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list<string>}
  --container-id: string
  --description: string
  --body-id: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/roles"))
  let req_body = {"attributes": $attributes, "clientRole": $client_role, "composite": $composite, "composites": $composites, "containerId": $container_id, "description": $description, "id": $body_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/clients/{id}/roles/{role_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list<string>>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/clients/{id}/roles/{role_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a role by name
#
# PUT /{realm}/clients/{id}/roles/{role-name}
# --composites shape: {client?: record, realm?: list<string>}
export def "clients-roles update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --client-role: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list<string>}
  --container-id: string
  --description: string
  --body-id: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/clients/{id}/roles/{role_name}"))
  let req_body = {"attributes": $attributes, "clientRole": $client_role, "composite": $composite, "composites": $composites, "containerId": $container_id, "description": $description, "id": $body_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/clients/{id}/roles/{role_name}/composites"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/clients/{id}/roles/{role_name}/composites"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a composite to the role
#
# POST /{realm}/clients/{id}/roles/{role-name}/composites
export def "clients-roles-composites create" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/clients/{id}/roles/{role_name}/composites"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_name: (encode-path-segment $role_name), client: (encode-path-segment $client)} | format pattern "/{realm}/clients/{id}/roles/{role_name}/composites/clients/{client}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/clients/{id}/roles/{role_name}/composites/realm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool> # if false, return a full representation of the GroupRepresentation objects
  --first: int # format: int32
  --max: int # format: int32
]: nothing -> table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let qp = [(serialize-qp "briefRepresentation" $brief_representation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/clients/{id}/roles/{role_name}/groups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"briefRepresentation": $brief_representation, "first": $first, "max": $max} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/clients/{id}/roles/{role_name}/management/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# PUT /{realm}/clients/{id}/roles/{role-name}/management/permissions
export def "clients-roles-management-permissions update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/clients/{id}/roles/{role_name}/management/permissions"))
  let req_body = {"enabled": $enabled, "resource": $resource, "scopePermissions": $scope_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first: int # format: int32
  --max: int # format: int32
]: nothing -> table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let qp = [(serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/clients/{id}/roles/{role_name}/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"first": $first, "max": $max} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/scope-mappings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/clients/{id}/scope-mappings/clients/{client}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the roles associated with a client’s scope Returns roles for the client.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/clients/{id}/scope-mappings/clients/{client}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add client-level roles to the client’s scope
#
# POST /{realm}/clients/{id}/scope-mappings/clients/{client}
export def "clients-scope-mappings-clients create" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/clients/{id}/scope-mappings/clients/{client}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# The available client-level roles Returns the roles for the client that can be associated with the client’s scope
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/clients/{id}/scope-mappings/clients/{client}/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get effective client roles Returns the roles for the client that are associated with the client’s scope.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/clients/{id}/scope-mappings/clients/{client}/composite"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/scope-mappings/realm"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/scope-mappings/realm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a set of realm-level roles to the client’s scope
#
# POST /{realm}/clients/{id}/scope-mappings/realm
export def "clients-scope-mappings-realm create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/scope-mappings/realm"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/scope-mappings/realm/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get effective realm-level roles associated with the client’s scope What this does is recurse any composite roles associated with the client’s scope and adds the roles to this lists.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/scope-mappings/realm/composite"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access: record, attributes: record, clientConsents: table<clientId: string, createdDate: int, grantedClientScopes: list, lastUpdatedDate: int>, clientRoles: record, createdTimestamp: int, credentials: table<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: table<identityProvider: string, userId: string, userName: string>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/service-account-user"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get application session count Returns a number of user sessions associated with this client { "count": number }
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/session-count"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Test if registered cluster nodes are available Tests availability by sending 'ping' request to all cluster nodes.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<failedRequests: list<string>, successRequests: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/test-nodes-available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get user sessions for client Returns a list of user sessions associated with this client
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first: int # Paging offset (format: int32)
  --max: int # Maximum results size (defaults to 100) (format: int32)
]: nothing -> table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/clients/{id}/user-sessions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"first": $first, "max": $max} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string
  --parent: string
  --type: string
]: nothing -> table<config: record<empty: bool, loadFactor: float, threshold: int>, id: string, name: string, parentId: string, providerId: string, providerType: string, subType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/components") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "parent": $parent, "type": $type} | compact), body: null}
}

# POST /{realm}/components
#
# --config shape: {empty?: bool, loadFactor?: float, threshold?: int}
export def "components create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record # shape: {empty?: bool, loadFactor?: float, threshold?: int}
  --id: string
  --name: string
  --parent-id: string
  --provider-id: string
  --provider-type: string
  --sub-type: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/components"))
  let req_body = {"config": $config, "id": $id, "name": $name, "parentId": $parent_id, "providerId": $provider_id, "providerType": $provider_type, "subType": $sub_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/components/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config: record<empty: bool, loadFactor: float, threshold: int>, id: string, name: string, parentId: string, providerId: string, providerType: string, subType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/components/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /{realm}/components/{id}
#
# --config shape: {empty?: bool, loadFactor?: float, threshold?: int}
export def "components update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record # shape: {empty?: bool, loadFactor?: float, threshold?: int}
  --body-id: string
  --name: string
  --parent-id: string
  --provider-id: string
  --provider-type: string
  --sub-type: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/components/{id}"))
  let req_body = {"config": $config, "id": $body_id, "name": $name, "parentId": $parent_id, "providerId": $provider_id, "providerType": $provider_type, "subType": $sub_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string
]: nothing -> table<helpText: string, id: string, metadata: record, properties: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/components/{id}/sub-component-types") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/credential-registrators"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/default-default-client-scopes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE /{realm}/default-default-client-scopes/{clientScopeId}
export def "default-default-client-scopes delete" [
  realm: string
  client_scope_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($client_scope_id | is-empty) { error make --unspanned { msg: "path parameter 'clientScopeId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), client_scope_id: (encode-path-segment $client_scope_id)} | format pattern "/{realm}/default-default-client-scopes/{client_scope_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /{realm}/default-default-client-scopes/{clientScopeId}
export def "default-default-client-scopes update" [
  realm: string
  client_scope_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($client_scope_id | is-empty) { error make --unspanned { msg: "path parameter 'clientScopeId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), client_scope_id: (encode-path-segment $client_scope_id)} | format pattern "/{realm}/default-default-client-scopes/{client_scope_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/default-groups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE /{realm}/default-groups/{groupId}
export def "default-groups delete" [
  realm: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), group_id: (encode-path-segment $group_id)} | format pattern "/{realm}/default-groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /{realm}/default-groups/{groupId}
export def "default-groups update" [
  realm: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), group_id: (encode-path-segment $group_id)} | format pattern "/{realm}/default-groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/default-optional-client-scopes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE /{realm}/default-optional-client-scopes/{clientScopeId}
export def "default-optional-client-scopes delete" [
  realm: string
  client_scope_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($client_scope_id | is-empty) { error make --unspanned { msg: "path parameter 'clientScopeId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), client_scope_id: (encode-path-segment $client_scope_id)} | format pattern "/{realm}/default-optional-client-scopes/{client_scope_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /{realm}/default-optional-client-scopes/{clientScopeId}
export def "default-optional-client-scopes update" [
  realm: string
  client_scope_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($client_scope_id | is-empty) { error make --unspanned { msg: "path parameter 'clientScopeId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), client_scope_id: (encode-path-segment $client_scope_id)} | format pattern "/{realm}/default-optional-client-scopes/{client_scope_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/events"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get events Returns all events, or filters them based on URL query parameters listed here
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client: string # App or oauth client name
  --date-from: string # From date
  --date-to: string # To date
  --first: int # Paging offset (format: int32)
  --ip-address: string # IP address
  --max: int # Maximum results size (defaults to 100) (format: int32)
  --type: list<string> # The types of events to return
  --user: string # User id
]: nothing -> table<clientId: string, details: record, error: string, ipAddress: string, realmId: string, sessionId: string, time: int, type: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let qp = [(serialize-qp "client" $client "scalar") (serialize-qp "dateFrom" $date_from "scalar") (serialize-qp "dateTo" $date_to "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "ipAddress" $ip_address "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "type" $type "multi") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"client": $client, "dateFrom": $date_from, "dateTo": $date_to, "first": $first, "ipAddress": $ip_address, "max": $max, "type": $type, "user": $user} | compact), body: null}
}

# Get the events provider configuration Returns JSON object with events provider configuration
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<adminEventsDetailsEnabled: bool, adminEventsEnabled: bool, enabledEventTypes: list<string>, eventsEnabled: bool, eventsExpiration: int, eventsListeners: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/events/config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the events provider Change the events provider and/or its configuration
#
# PUT /{realm}/events/config
export def "events-config update" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin-events-details-enabled: oneof<nothing, bool>
  --admin-events-enabled: oneof<nothing, bool>
  --enabled-event-types: list<string>
  --events-enabled: oneof<nothing, bool>
  --events-expiration: int # format: int64
  --events-listeners: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/events/config"))
  let req_body = {"adminEventsDetailsEnabled": $admin_events_details_enabled, "adminEventsEnabled": $admin_events_enabled, "enabledEventTypes": $enabled_event_types, "eventsEnabled": $events_enabled, "eventsExpiration": $events_expiration, "eventsListeners": $events_listeners} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($path | is-empty) { error make --unspanned { msg: "path parameter 'path' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), path: (encode-path-segment $path)} | format pattern "/{realm}/group-by-path/{path}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool>
  --first: int # format: int32
  --max: int # format: int32
  --search: string
]: nothing -> table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let qp = [(serialize-qp "briefRepresentation" $brief_representation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/groups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"briefRepresentation": $brief_representation, "first": $first, "max": $max, "search": $search} | compact), body: null}
}

# create or add a top level realm groupSet or create child.
#
# POST /{realm}/groups
# --subGroups item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
export def "groups create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --attributes: record
  --client-roles: record
  --id: string
  --name: string
  --path: string
  --realm-roles: list<string>
  --sub-groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/groups"))
  let req_body = {"access": $access, "attributes": $attributes, "clientRoles": $client_roles, "id": $id, "name": $name, "path": $path, "realmRoles": $realm_roles, "subGroups": $sub_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
  --top: oneof<nothing, bool>
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/groups/count") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "top": $top} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update group, ignores subgroups.
#
# PUT /{realm}/groups/{id}
# --subGroups item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
export def "groups update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --attributes: record
  --client-roles: record
  --body-id: string
  --name: string
  --path: string
  --realm-roles: list<string>
  --sub-groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}"))
  let req_body = {"access": $access, "attributes": $attributes, "clientRoles": $client_roles, "id": $body_id, "name": $name, "path": $path, "realmRoles": $realm_roles, "subGroups": $sub_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Set or create child.
#
# POST /{realm}/groups/{id}/children
# --subGroups item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
export def "groups-children create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --attributes: record
  --client-roles: record
  --body-id: string
  --name: string
  --path: string
  --realm-roles: list<string>
  --sub-groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}/children"))
  let req_body = {"access": $access, "attributes": $attributes, "clientRoles": $client_roles, "id": $body_id, "name": $name, "path": $path, "realmRoles": $realm_roles, "subGroups": $sub_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}/management/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# PUT /{realm}/groups/{id}/management/permissions
export def "groups-management-permissions update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}/management/permissions"))
  let req_body = {"enabled": $enabled, "resource": $resource, "scopePermissions": $scope_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get users Returns a list of users, filtered according to query parameters
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool> # Only return basic information (only guaranteed to return id, username, created, first and last name, email, enabled state, email verification state, federation link, and access. Note that it means that namely user attributes, required actions, and not before are not returned.)
  --first: int # Pagination offset (format: int32)
  --max: int # Maximum results size (defaults to 100) (format: int32)
]: nothing -> table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "briefRepresentation" $brief_representation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"briefRepresentation": $brief_representation, "first": $first, "max": $max} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}/role-mappings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/groups/{id}/role-mappings/clients/{client}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/groups/{id}/role-mappings/clients/{client}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add client-level roles to the user role mapping
#
# POST /{realm}/groups/{id}/role-mappings/clients/{client}
export def "groups-role-mappings-clients create" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/groups/{id}/role-mappings/clients/{client}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/groups/{id}/role-mappings/clients/{client}/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get effective client-level role mappings This recurses any composite roles
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/groups/{id}/role-mappings/clients/{client}/composite"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}/role-mappings/realm"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}/role-mappings/realm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add realm-level role mappings to the user
#
# POST /{realm}/groups/{id}/role-mappings/realm
export def "groups-role-mappings-realm create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}/role-mappings/realm"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}/role-mappings/realm/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get effective realm-level role mappings This will recurse all composite roles to get the result.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/groups/{id}/role-mappings/realm/composite"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Import identity provider from uploaded JSON file
#
# POST /{realm}/identity-provider/import-config
export def "identity-provider-import-config create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/identity-provider/import-config"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/identity-provider/instances"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new identity provider
#
# POST /{realm}/identity-provider/instances
export def "identity-provider-instances create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-read-token-role-on-create: oneof<nothing, bool>
  --alias: string
  --config: record
  --display-name: string
  --enabled: oneof<nothing, bool>
  --first-broker-login-flow-alias: string
  --internal-id: string
  --link-only: oneof<nothing, bool>
  --post-broker-login-flow-alias: string
  --provider-id: string
  --store-token: oneof<nothing, bool>
  --trust-email: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/identity-provider/instances"))
  let req_body = {"addReadTokenRoleOnCreate": $add_read_token_role_on_create, "alias": $alias, "config": $config, "displayName": $display_name, "enabled": $enabled, "firstBrokerLoginFlowAlias": $first_broker_login_flow_alias, "internalId": $internal_id, "linkOnly": $link_only, "postBrokerLoginFlowAlias": $post_broker_login_flow_alias, "providerId": $provider_id, "storeToken": $store_token, "trustEmail": $trust_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/identity-provider/instances/{alias}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/identity-provider/instances/{alias}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the identity provider
#
# PUT /{realm}/identity-provider/instances/{alias}
export def "identity-provider-instances update" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-read-token-role-on-create: oneof<nothing, bool>
  --body-alias: string
  --config: record
  --display-name: string
  --enabled: oneof<nothing, bool>
  --first-broker-login-flow-alias: string
  --internal-id: string
  --link-only: oneof<nothing, bool>
  --post-broker-login-flow-alias: string
  --provider-id: string
  --store-token: oneof<nothing, bool>
  --trust-email: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/identity-provider/instances/{alias}"))
  let req_body = {"addReadTokenRoleOnCreate": $add_read_token_role_on_create, "alias": $body_alias, "config": $config, "displayName": $display_name, "enabled": $enabled, "firstBrokerLoginFlowAlias": $first_broker_login_flow_alias, "internalId": $internal_id, "linkOnly": $link_only, "postBrokerLoginFlowAlias": $post_broker_login_flow_alias, "providerId": $provider_id, "storeToken": $store_token, "trustEmail": $trust_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # Format to use
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/identity-provider/instances/{alias}/export") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/identity-provider/instances/{alias}/management/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return object stating whether client Authorization permissions have been initialized or not and a reference
#
# PUT /{realm}/identity-provider/instances/{alias}/management/permissions
export def "identity-provider-instances-management-permissions update" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/identity-provider/instances/{alias}/management/permissions"))
  let req_body = {"enabled": $enabled, "resource": $resource, "scopePermissions": $scope_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/identity-provider/instances/{alias}/mapper-types"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/identity-provider/instances/{alias}/mappers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a mapper to identity provider
#
# POST /{realm}/identity-provider/instances/{alias}/mappers
export def "identity-provider-instances-mappers create" [
  realm: string
  alias: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --id: string
  --identity-provider-alias: string
  --identity-provider-mapper: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias)} | format pattern "/{realm}/identity-provider/instances/{alias}/mappers"))
  let req_body = {"config": $config, "id": $id, "identityProviderAlias": $identity_provider_alias, "identityProviderMapper": $identity_provider_mapper, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias), id: (encode-path-segment $id)} | format pattern "/{realm}/identity-provider/instances/{alias}/mappers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias), id: (encode-path-segment $id)} | format pattern "/{realm}/identity-provider/instances/{alias}/mappers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a mapper for the identity provider
#
# PUT /{realm}/identity-provider/instances/{alias}/mappers/{id}
export def "identity-provider-instances-mappers update" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --config: record
  --body-id: string
  --identity-provider-alias: string
  --identity-provider-mapper: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($alias | is-empty) { error make --unspanned { msg: "path parameter 'alias' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), alias: (encode-path-segment $alias), id: (encode-path-segment $id)} | format pattern "/{realm}/identity-provider/instances/{alias}/mappers/{id}"))
  let req_body = {"config": $config, "id": $body_id, "identityProviderAlias": $identity_provider_alias, "identityProviderMapper": $identity_provider_mapper, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($provider_id | is-empty) { error make --unspanned { msg: "path parameter 'provider_id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), provider_id: (encode-path-segment $provider_id)} | format pattern "/{realm}/identity-provider/providers/{provider_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: record, keys: table<algorithm: string, certificate: string, kid: string, providerId: string, providerPriority: int, publicKey: string, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Removes all user sessions.
#
# POST /{realm}/logout-all
export def "logout-all create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/logout-all"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Partial export of existing realm into a JSON file.
#
# POST /{realm}/partial-export
export def "partial-export create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --export-clients: oneof<nothing, bool>
  --export-groups-and-roles: oneof<nothing, bool>
]: nothing -> record<accessCodeLifespan: int, accessCodeLifespanLogin: int, accessCodeLifespanUserAction: int, accessTokenLifespan: int, accessTokenLifespanForImplicitFlow: int, accountTheme: string, actionTokenGeneratedByAdminLifespan: int, actionTokenGeneratedByUserLifespan: int, adminEventsDetailsEnabled: bool, adminEventsEnabled: bool, adminTheme: string, attributes: record, authenticationFlows: table<alias: string, authenticationExecutions: list, builtIn: bool, description: string, id: string, providerId: string, topLevel: bool>, authenticatorConfig: table<alias: string, config: record, id: string>, browserFlow: string, browserSecurityHeaders: record, bruteForceProtected: bool, clientAuthenticationFlow: string, clientScopeMappings: record, clientScopes: table<attributes: record, description: string, id: string, name: string, protocol: string, protocolMappers: list>, clientSessionIdleTimeout: int, clientSessionMaxLifespan: int, clients: table<access: record, adminUrl: string, alwaysDisplayInConsole: bool, attributes: record, authenticationFlowBindingOverrides: record, authorizationServicesEnabled: bool, authorizationSettings: record, baseUrl: string, bearerOnly: bool, clientAuthenticatorType: string, clientId: string, consentRequired: bool, defaultClientScopes: list, defaultRoles: list, description: string, directAccessGrantsEnabled: bool, enabled: bool, frontchannelLogout: bool, fullScopeAllowed: bool, id: string, implicitFlowEnabled: bool, name: string, nodeReRegistrationTimeout: int, notBefore: int, optionalClientScopes: list, origin: string, protocol: string, protocolMappers: list, publicClient: bool, redirectUris: list, registeredNodes: record, registrationAccessToken: string, rootUrl: string, secret: string, serviceAccountsEnabled: bool, standardFlowEnabled: bool, surrogateAuthRequired: bool, webOrigins: list>, components: record<empty: bool, loadFactor: float, threshold: int>, defaultDefaultClientScopes: list<string>, defaultGroups: list<string>, defaultLocale: string, defaultOptionalClientScopes: list<string>, defaultRoles: list<string>, defaultSignatureAlgorithm: string, directGrantFlow: string, displayName: string, displayNameHtml: string, dockerAuthenticationFlow: string, duplicateEmailsAllowed: bool, editUsernameAllowed: bool, emailTheme: string, enabled: bool, enabledEventTypes: list<string>, eventsEnabled: bool, eventsExpiration: int, eventsListeners: list<string>, failureFactor: int, federatedUsers: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, groups: table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list, subGroups: list>, id: string, identityProviderMappers: table<config: record, id: string, identityProviderAlias: string, identityProviderMapper: string, name: string>, identityProviders: table<addReadTokenRoleOnCreate: bool, alias: string, config: record, displayName: string, enabled: bool, firstBrokerLoginFlowAlias: string, internalId: string, linkOnly: bool, postBrokerLoginFlowAlias: string, providerId: string, storeToken: bool, trustEmail: bool>, internationalizationEnabled: bool, keycloakVersion: string, loginTheme: string, loginWithEmailAllowed: bool, maxDeltaTimeSeconds: int, maxFailureWaitSeconds: int, minimumQuickLoginWaitSeconds: int, notBefore: int, offlineSessionIdleTimeout: int, offlineSessionMaxLifespan: int, offlineSessionMaxLifespanEnabled: bool, otpPolicyAlgorithm: string, otpPolicyDigits: int, otpPolicyInitialCounter: int, otpPolicyLookAheadWindow: int, otpPolicyPeriod: int, otpPolicyType: string, otpSupportedApplications: list<string>, passwordPolicy: string, permanentLockout: bool, protocolMappers: table<config: record, id: string, name: string, protocol: string, protocolMapper: string>, quickLoginCheckMilliSeconds: int, realm: string, refreshTokenMaxReuse: int, registrationAllowed: bool, registrationEmailAsUsername: bool, registrationFlow: string, rememberMe: bool, requiredActions: table<alias: string, config: record, defaultAction: bool, enabled: bool, name: string, priority: int, providerId: string>, resetCredentialsFlow: string, resetPasswordAllowed: bool, revokeRefreshToken: bool, roles: record<client: record, realm: list<record>>, scopeMappings: table<client: string, clientScope: string, roles: list, self: string>, smtpServer: record, sslRequired: string, ssoSessionIdleTimeout: int, ssoSessionIdleTimeoutRememberMe: int, ssoSessionMaxLifespan: int, ssoSessionMaxLifespanRememberMe: int, supportedLocales: list<string>, userFederationMappers: table<config: record, federationMapperType: string, federationProviderDisplayName: string, id: string, name: string>, userFederationProviders: table<changedSyncPeriod: int, config: record, displayName: string, fullSyncPeriod: int, id: string, lastSync: int, priority: int, providerName: string>, userManagedAccessAllowed: bool, users: table<access: record, attributes: record, clientConsents: list, clientRoles: record, createdTimestamp: int, credentials: list, disableableCredentialTypes: list, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list, federationLink: string, firstName: string, groups: list, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list, requiredActions: list, self: string, serviceAccountClientId: string, username: string>, verifyEmail: bool, waitIncrementSeconds: int, webAuthnPolicyAcceptableAaguids: list<string>, webAuthnPolicyAttestationConveyancePreference: string, webAuthnPolicyAuthenticatorAttachment: string, webAuthnPolicyAvoidSameAuthenticatorRegister: bool, webAuthnPolicyCreateTimeout: int, webAuthnPolicyPasswordlessAcceptableAaguids: list<string>, webAuthnPolicyPasswordlessAttestationConveyancePreference: string, webAuthnPolicyPasswordlessAuthenticatorAttachment: string, webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister: bool, webAuthnPolicyPasswordlessCreateTimeout: int, webAuthnPolicyPasswordlessRequireResidentKey: string, webAuthnPolicyPasswordlessRpEntityName: string, webAuthnPolicyPasswordlessRpId: string, webAuthnPolicyPasswordlessSignatureAlgorithms: list<string>, webAuthnPolicyPasswordlessUserVerificationRequirement: string, webAuthnPolicyRequireResidentKey: string, webAuthnPolicyRpEntityName: string, webAuthnPolicyRpId: string, webAuthnPolicySignatureAlgorithms: list<string>, webAuthnPolicyUserVerificationRequirement: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let qp = [(serialize-qp "exportClients" $export_clients "scalar") (serialize-qp "exportGroupsAndRoles" $export_groups_and_roles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/partial-export") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"exportClients": $export_clients, "exportGroupsAndRoles": $export_groups_and_roles} | compact), body: null}
}

# Partial import from a JSON file to an existing realm.
#
# POST /{realm}/partialImport
# --clients item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list<string>, defaultRoles?: list<string>, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, ... (20 more fields)}
# --groups item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
# --identityProviders item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
# --roles shape: {client?: record, realm?: list}
# --users item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
export def "partial-import create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clients: list # item shape: {access?: record, adminUrl?: string, alwaysDisplayInConsole?: bool, attributes?: record, authenticationFlowBindingOverrides?: record, authorizationServicesEnabled?: bool, authorizationSettings?: record, baseUrl?: string, bearerOnly?: bool, clientAuthenticatorType?: string, clientId?: string, consentRequired?: bool, defaultClientScopes?: list<string>, defaultRoles?: list<string>, description?: string, directAccessGrantsEnabled?: bool, enabled?: bool, frontchannelLogout?: bool, ... (20 more fields)}
  --groups: list # item shape: {access?: record, attributes?: record, clientRoles?: record, id?: string, name?: string, path?: string, realmRoles?: list<string>, subGroups?: list}
  --identity-providers: list # item shape: {addReadTokenRoleOnCreate?: bool, alias?: string, config?: record, displayName?: string, enabled?: bool, firstBrokerLoginFlowAlias?: string, internalId?: string, linkOnly?: bool, postBrokerLoginFlowAlias?: string, providerId?: string, storeToken?: bool, trustEmail?: bool}
  --if-resource-exists: string
  --policy: string@policy-completer
  --roles: record # shape: {client?: record, realm?: list}
  --users: list # item shape: {access?: record, attributes?: record, clientConsents?: list, clientRoles?: record, createdTimestamp?: int, credentials?: list, disableableCredentialTypes?: list<string>, email?: string, emailVerified?: bool, enabled?: bool, federatedIdentities?: list, federationLink?: string, firstName?: string, groups?: list<string>, id?: string, lastName?: string, notBefore?: int, origin?: string, realmRoles?: list<string>, requiredActions?: list<string>, self?: string, serviceAccountClientId?: string, ... (1 more fields)}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/partialImport"))
  let req_body = {"clients": $clients, "groups": $groups, "identityProviders": $identity_providers, "ifResourceExists": $if_resource_exists, "policy": $policy, "roles": $roles, "users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Push the realm’s revocation policy to any client that has an admin url associated with it.
#
# POST /{realm}/push-revocation
export def "push-revocation create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/push-revocation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool>
  --first: int # format: int32
  --max: int # format: int32
  --search: string
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let qp = [(serialize-qp "briefRepresentation" $brief_representation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/roles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"briefRepresentation": $brief_representation, "first": $first, "max": $max, "search": $search} | compact), body: null}
}

# Create a new role for the realm or client
#
# POST /{realm}/roles
# --composites shape: {client?: record, realm?: list<string>}
export def "roles create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --client-role: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list<string>}
  --container-id: string
  --description: string
  --id: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/roles"))
  let req_body = {"attributes": $attributes, "clientRole": $client_role, "composite": $composite, "composites": $composites, "containerId": $container_id, "description": $description, "id": $id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role-id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_id: (encode-path-segment $role_id)} | format pattern "/{realm}/roles-by-id/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list<string>>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role-id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_id: (encode-path-segment $role_id)} | format pattern "/{realm}/roles-by-id/{role_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the role
#
# PUT /{realm}/roles-by-id/{role-id}
# --composites shape: {client?: record, realm?: list<string>}
export def "roles-by-id update" [
  realm: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --client-role: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list<string>}
  --container-id: string
  --description: string
  --id: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role-id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_id: (encode-path-segment $role_id)} | format pattern "/{realm}/roles-by-id/{role_id}"))
  let req_body = {"attributes": $attributes, "clientRole": $client_role, "composite": $composite, "composites": $composites, "containerId": $container_id, "description": $description, "id": $id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role-id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_id: (encode-path-segment $role_id)} | format pattern "/{realm}/roles-by-id/{role_id}/composites"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get role’s children Returns a set of role’s children provided the role is a composite.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role-id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_id: (encode-path-segment $role_id)} | format pattern "/{realm}/roles-by-id/{role_id}/composites"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Make the role a composite role by associating some child roles
#
# POST /{realm}/roles-by-id/{role-id}/composites
export def "roles-by-id-composites create" [
  realm: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role-id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_id: (encode-path-segment $role_id)} | format pattern "/{realm}/roles-by-id/{role_id}/composites"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role-id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_id: (encode-path-segment $role_id), client: (encode-path-segment $client)} | format pattern "/{realm}/roles-by-id/{role_id}/composites/clients/{client}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role-id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_id: (encode-path-segment $role_id)} | format pattern "/{realm}/roles-by-id/{role_id}/composites/realm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role-id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_id: (encode-path-segment $role_id)} | format pattern "/{realm}/roles-by-id/{role_id}/management/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# PUT /{realm}/roles-by-id/{role-id}/management/permissions
export def "roles-by-id-management-permissions update" [
  realm: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_id | is-empty) { error make --unspanned { msg: "path parameter 'role-id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_id: (encode-path-segment $role_id)} | format pattern "/{realm}/roles-by-id/{role_id}/management/permissions"))
  let req_body = {"enabled": $enabled, "resource": $resource, "scopePermissions": $scope_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/roles/{role_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list<string>>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/roles/{role_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a role by name
#
# PUT /{realm}/roles/{role-name}
# --composites shape: {client?: record, realm?: list<string>}
export def "roles update" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributes: record
  --client-role: oneof<nothing, bool>
  --composite: oneof<nothing, bool>
  --composites: record # shape: {client?: record, realm?: list<string>}
  --container-id: string
  --description: string
  --id: string
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/roles/{role_name}"))
  let req_body = {"attributes": $attributes, "clientRole": $client_role, "composite": $composite, "composites": $composites, "containerId": $container_id, "description": $description, "id": $id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/roles/{role_name}/composites"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/roles/{role_name}/composites"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a composite to the role
#
# POST /{realm}/roles/{role-name}/composites
export def "roles-composites create" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/roles/{role_name}/composites"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_name: (encode-path-segment $role_name), client: (encode-path-segment $client)} | format pattern "/{realm}/roles/{role_name}/composites/clients/{client}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/roles/{role_name}/composites/realm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool> # if false, return a full representation of the GroupRepresentation objects
  --first: int # format: int32
  --max: int # format: int32
]: nothing -> table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let qp = [(serialize-qp "briefRepresentation" $brief_representation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/roles/{role_name}/groups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"briefRepresentation": $brief_representation, "first": $first, "max": $max} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/roles/{role_name}/management/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Return object stating whether role Authoirzation permissions have been initialized or not and a reference
#
# PUT /{realm}/roles/{role-name}/management/permissions
export def "roles-management-permissions update" [
  realm: string
  role_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/roles/{role_name}/management/permissions"))
  let req_body = {"enabled": $enabled, "resource": $resource, "scopePermissions": $scope_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first: int # format: int32
  --max: int # format: int32
]: nothing -> table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($role_name | is-empty) { error make --unspanned { msg: "path parameter 'role-name' must be non-empty" } }
  let qp = [(serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), role_name: (encode-path-segment $role_name)} | format pattern "/{realm}/roles/{role_name}/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"first": $first, "max": $max} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($session | is-empty) { error make --unspanned { msg: "path parameter 'session' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), session: (encode-path-segment $session)} | format pattern "/{realm}/sessions/{session}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Test LDAP connection
#
# POST /{realm}/testLDAPConnection
export def "test-ldap-connection create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string
  --bind-credential: string
  --bind-dn: string
  --component-id: string
  --connection-timeout: string
  --connection-url: string
  --start-tls: string
  --use-truststore-spi: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/testLDAPConnection"))
  let req_body = {"action": $action, "bindCredential": $bind_credential, "bindDn": $bind_dn, "componentId": $component_id, "connectionTimeout": $connection_timeout, "connectionUrl": $connection_url, "startTls": $start_tls, "useTruststoreSpi": $use_truststore_spi} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /{realm}/testSMTPConnection
export def "test-smtp-connection create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/testSMTPConnection"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Need this for admin console to display simple name of provider when displaying user detail KEYCLOAK-4328
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/user-storage/{id}/name"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove imported users
#
# POST /{realm}/user-storage/{id}/remove-imported-users
export def "user-storage-remove-imported-users create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/user-storage/{id}/remove-imported-users"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Trigger sync of users Action can be "triggerFullSync" or "triggerChangedUsersSync"
#
# POST /{realm}/user-storage/{id}/sync
export def "user-storage-sync create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string
]: nothing -> record<added: int, failed: int, ignored: bool, removed: int, status: string, updated: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/user-storage/{id}/sync") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"action": $action} | compact), body: null}
}

# Unlink imported users from a storage provider
#
# POST /{realm}/user-storage/{id}/unlink-users
export def "user-storage-unlink-users create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/user-storage/{id}/unlink-users"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Trigger sync of mapper data related to ldap mapper (roles, groups, …​) direction is "fedToKeycloak" or "keycloakToFed"
#
# POST /{realm}/user-storage/{parentId}/mappers/{id}/sync
export def "user-storage-mappers-sync create" [
  realm: string
  parent_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direction: string
]: nothing -> record<added: int, failed: int, ignored: bool, removed: int, status: string, updated: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($parent_id | is-empty) { error make --unspanned { msg: "path parameter 'parentId' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), parent_id: (encode-path-segment $parent_id), id: (encode-path-segment $id)} | format pattern "/{realm}/user-storage/{parent_id}/mappers/{id}/sync") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"direction": $direction} | compact), body: null}
}

# Get users Returns a list of users, filtered according to query parameters
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool>
  --email: string
  --first: int # format: int32
  --first-name: string
  --last-name: string
  --max: int # Maximum results size (defaults to 100) (format: int32)
  --search: string # A String contained in username, first or last name, or email
  --username: string
]: nothing -> table<access: record, attributes: record, clientConsents: list<record>, clientRoles: record, createdTimestamp: int, credentials: list<record>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: list<record>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let qp = [(serialize-qp "briefRepresentation" $brief_representation "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "firstName" $first_name "scalar") (serialize-qp "lastName" $last_name "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"briefRepresentation": $brief_representation, "email": $email, "first": $first, "firstName": $first_name, "lastName": $last_name, "max": $max, "search": $search, "username": $username} | compact), body: null}
}

# Create a new user Username must be unique.
#
# POST /{realm}/users
# --clientConsents item shape: {clientId?: string, createdDate?: int, grantedClientScopes?: list<string>, lastUpdatedDate?: int}
# --credentials item shape: {createdDate?: int, credentialData?: string, id?: string, priority?: int, secretData?: string, temporary?: bool, type?: string, userLabel?: string, value?: string}
# --federatedIdentities item shape: {identityProvider?: string, userId?: string, userName?: string}
export def "users create" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --attributes: record
  --client-consents: list # item shape: {clientId?: string, createdDate?: int, grantedClientScopes?: list<string>, lastUpdatedDate?: int}
  --client-roles: record
  --created-timestamp: int # format: int64
  --credentials: list # item shape: {createdDate?: int, credentialData?: string, id?: string, priority?: int, secretData?: string, temporary?: bool, type?: string, userLabel?: string, value?: string}
  --disableable-credential-types: list<string>
  --email: string
  --email-verified: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --federated-identities: list # item shape: {identityProvider?: string, userId?: string, userName?: string}
  --federation-link: string
  --first-name: string
  --groups: list<string>
  --id: string
  --last-name: string
  --not-before: int # format: int32
  --origin: string
  --realm-roles: list<string>
  --required-actions: list<string>
  --self: string
  --service-account-client-id: string
  --username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/users"))
  let req_body = {"access": $access, "attributes": $attributes, "clientConsents": $client_consents, "clientRoles": $client_roles, "createdTimestamp": $created_timestamp, "credentials": $credentials, "disableableCredentialTypes": $disableable_credential_types, "email": $email, "emailVerified": $email_verified, "enabled": $enabled, "federatedIdentities": $federated_identities, "federationLink": $federation_link, "firstName": $first_name, "groups": $groups, "id": $id, "lastName": $last_name, "notBefore": $not_before, "origin": $origin, "realmRoles": $realm_roles, "requiredActions": $required_actions, "self": $self, "serviceAccountClientId": $service_account_client_id, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<enabled: bool, resource: string, scopePermissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/users-management-permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /{realm}/users-management-permissions
export def "users-management-permissions update" [
  realm: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool>
  --resource: string
  --scope-permissions: record
]: any -> record<enabled: bool, resource: string, scopePermissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/users-management-permissions"))
  let req_body = {"enabled": $enabled, "resource": $resource, "scopePermissions": $scope_permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # email filter
  --first-name: string # first name filter
  --last-name: string # last name filter
  --search: string # arbitrary search string for all the fields below
  --username: string # username filter
]: nothing -> oneof<int, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "firstName" $first_name "scalar") (serialize-qp "lastName" $last_name "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "username" $username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm)} | format pattern "/{realm}/users/count") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"email": $email, "firstName": $first_name, "lastName": $last_name, "search": $search, "username": $username} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access: record, attributes: record, clientConsents: table<clientId: string, createdDate: int, grantedClientScopes: list, lastUpdatedDate: int>, clientRoles: record, createdTimestamp: int, credentials: table<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string>, disableableCredentialTypes: list<string>, email: string, emailVerified: bool, enabled: bool, federatedIdentities: table<identityProvider: string, userId: string, userName: string>, federationLink: string, firstName: string, groups: list<string>, id: string, lastName: string, notBefore: int, origin: string, realmRoles: list<string>, requiredActions: list<string>, self: string, serviceAccountClientId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the user
#
# PUT /{realm}/users/{id}
# --clientConsents item shape: {clientId?: string, createdDate?: int, grantedClientScopes?: list<string>, lastUpdatedDate?: int}
# --credentials item shape: {createdDate?: int, credentialData?: string, id?: string, priority?: int, secretData?: string, temporary?: bool, type?: string, userLabel?: string, value?: string}
# --federatedIdentities item shape: {identityProvider?: string, userId?: string, userName?: string}
export def "users update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --access: record
  --attributes: record
  --client-consents: list # item shape: {clientId?: string, createdDate?: int, grantedClientScopes?: list<string>, lastUpdatedDate?: int}
  --client-roles: record
  --created-timestamp: int # format: int64
  --credentials: list # item shape: {createdDate?: int, credentialData?: string, id?: string, priority?: int, secretData?: string, temporary?: bool, type?: string, userLabel?: string, value?: string}
  --disableable-credential-types: list<string>
  --email: string
  --email-verified: oneof<nothing, bool>
  --enabled: oneof<nothing, bool>
  --federated-identities: list # item shape: {identityProvider?: string, userId?: string, userName?: string}
  --federation-link: string
  --first-name: string
  --groups: list<string>
  --body-id: string
  --last-name: string
  --not-before: int # format: int32
  --origin: string
  --realm-roles: list<string>
  --required-actions: list<string>
  --self: string
  --service-account-client-id: string
  --username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}"))
  let req_body = {"access": $access, "attributes": $attributes, "clientConsents": $client_consents, "clientRoles": $client_roles, "createdTimestamp": $created_timestamp, "credentials": $credentials, "disableableCredentialTypes": $disableable_credential_types, "email": $email, "emailVerified": $email_verified, "enabled": $enabled, "federatedIdentities": $federated_identities, "federationLink": $federation_link, "firstName": $first_name, "groups": $groups, "id": $body_id, "lastName": $last_name, "notBefore": $not_before, "origin": $origin, "realmRoles": $realm_roles, "requiredActions": $required_actions, "self": $self, "serviceAccountClientId": $service_account_client_id, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/configured-user-storage-credential-types"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/consents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/users/{id}/consents/{client}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<createdDate: int, credentialData: string, id: string, priority: int, secretData: string, temporary: bool, type: string, userLabel: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/credentials"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove a credential for a user
#
# DELETE /{realm}/users/{id}/credentials/{credentialId}
export def "users-credentials delete" [
  realm: string
  id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($credential_id | is-empty) { error make --unspanned { msg: "path parameter 'credentialId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), credential_id: (encode-path-segment $credential_id)} | format pattern "/{realm}/users/{id}/credentials/{credential_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Move a credential to a position behind another credential
#
# POST /{realm}/users/{id}/credentials/{credentialId}/moveAfter/{newPreviousCredentialId}
export def "users-credentials-move-after create" [
  realm: string
  id: string
  credential_id: string
  new_previous_credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($credential_id | is-empty) { error make --unspanned { msg: "path parameter 'credentialId' must be non-empty" } }
  if ($new_previous_credential_id | is-empty) { error make --unspanned { msg: "path parameter 'newPreviousCredentialId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), credential_id: (encode-path-segment $credential_id), new_previous_credential_id: (encode-path-segment $new_previous_credential_id)} | format pattern "/{realm}/users/{id}/credentials/{credential_id}/moveAfter/{new_previous_credential_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Move a credential to a first position in the credentials list of the user
#
# POST /{realm}/users/{id}/credentials/{credentialId}/moveToFirst
export def "users-credentials-move-to-first create" [
  realm: string
  id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($credential_id | is-empty) { error make --unspanned { msg: "path parameter 'credentialId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), credential_id: (encode-path-segment $credential_id)} | format pattern "/{realm}/users/{id}/credentials/{credential_id}/moveToFirst"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a credential label for a user
#
# PUT /{realm}/users/{id}/credentials/{credentialId}/userLabel
export def "users-credentials-user-label update" [
  realm: string
  id: string
  credential_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($credential_id | is-empty) { error make --unspanned { msg: "path parameter 'credentialId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), credential_id: (encode-path-segment $credential_id)} | format pattern "/{realm}/users/{id}/credentials/{credential_id}/userLabel"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "text/plain" $req_body {query: {}, body: $req_body}
}

# Disable all credentials for a user of a specific type
#
# PUT /{realm}/users/{id}/disable-credential-types
export def "users-disable-credential-types update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/disable-credential-types"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Send a update account email to the user An email contains a link the user can click to perform a set of required actions.
#
# PUT /{realm}/users/{id}/execute-actions-email
export def "users-execute-actions-email update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Client id
  --lifespan: int # Number of seconds after which the generated token expires (format: int32)
  --redirect-uri: string # Redirect uri
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "lifespan" $lifespan "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/execute-actions-email") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"client_id": $client_id, "lifespan": $lifespan, "redirect_uri": $redirect_uri} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<identityProvider: string, userId: string, userName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/federated-identity"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), provider: (encode-path-segment $provider)} | format pattern "/{realm}/users/{id}/federated-identity/{provider}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a social login provider to the user
#
# POST /{realm}/users/{id}/federated-identity/{provider}
export def "users-federated-identity create" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity-provider: string
  --user-id: string
  --user-name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($provider | is-empty) { error make --unspanned { msg: "path parameter 'provider' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), provider: (encode-path-segment $provider)} | format pattern "/{realm}/users/{id}/federated-identity/{provider}"))
  let req_body = {"identityProvider": $identity_provider, "userId": $user_id, "userName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --brief-representation: oneof<nothing, bool>
  --first: int # format: int32
  --max: int # format: int32
  --search: string
]: nothing -> table<access: record, attributes: record, clientRoles: record, id: string, name: string, path: string, realmRoles: list<string>, subGroups: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "briefRepresentation" $brief_representation "scalar") (serialize-qp "first" $first "scalar") (serialize-qp "max" $max "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/groups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"briefRepresentation": $brief_representation, "first": $first, "max": $max, "search": $search} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/groups/count") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search} | compact), body: null}
}

# DELETE /{realm}/users/{id}/groups/{groupId}
export def "users-groups delete" [
  realm: string
  id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), group_id: (encode-path-segment $group_id)} | format pattern "/{realm}/users/{id}/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# PUT /{realm}/users/{id}/groups/{groupId}
export def "users-groups update" [
  realm: string
  id: string
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), group_id: (encode-path-segment $group_id)} | format pattern "/{realm}/users/{id}/groups/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Impersonate the user
#
# POST /{realm}/users/{id}/impersonation
export def "users-impersonation create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/impersonation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove all user sessions associated with the user Also send notification to all clients that have an admin URL to invalidate the sessions for the particular user.
#
# POST /{realm}/users/{id}/logout
export def "users-logout create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/logout"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get offline sessions associated with the user and client
#
# GET /{realm}/users/{id}/offline-sessions/{clientId}
export def "users-offline-sessions get" [
  realm: string
  id: string
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'clientId' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client_id: (encode-path-segment $client_id)} | format pattern "/{realm}/users/{id}/offline-sessions/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Set up a new password for the user.
#
# PUT /{realm}/users/{id}/reset-password
export def "users-reset-password update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-date: int # format: int64
  --credential-data: string
  --body-id: string
  --priority: int # format: int32
  --secret-data: string
  --temporary: oneof<nothing, bool>
  --type: string
  --user-label: string
  --value: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/reset-password"))
  let req_body = {"createdDate": $created_date, "credentialData": $credential_data, "id": $body_id, "priority": $priority, "secretData": $secret_data, "temporary": $temporary, "type": $type, "userLabel": $user_label, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clientMappings: record, realmMappings: table<attributes: record, clientRole: bool, composite: bool, composites: record, containerId: string, description: string, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/role-mappings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/users/{id}/role-mappings/clients/{client}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/users/{id}/role-mappings/clients/{client}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add client-level roles to the user role mapping
#
# POST /{realm}/users/{id}/role-mappings/clients/{client}
export def "users-role-mappings-clients create" [
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/users/{id}/role-mappings/clients/{client}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/users/{id}/role-mappings/clients/{client}/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get effective client-level role mappings This recurses any composite roles
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($client | is-empty) { error make --unspanned { msg: "path parameter 'client' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id), client: (encode-path-segment $client)} | format pattern "/{realm}/users/{id}/role-mappings/clients/{client}/composite"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/role-mappings/realm"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/role-mappings/realm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add realm-level role mappings to the user
#
# POST /{realm}/users/{id}/role-mappings/realm
export def "users-role-mappings-realm create" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/role-mappings/realm"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/role-mappings/realm/available"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get effective realm-level role mappings This will recurse all composite roles to get the result.
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<attributes: record, clientRole: bool, composite: bool, composites: record<client: record, realm: list>, containerId: string, description: string, id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/role-mappings/realm/composite"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Send an email-verification email to the user An email contains a link the user can click to verify their email address.
#
# PUT /{realm}/users/{id}/send-verify-email
export def "users-send-verify-email update" [
  realm: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Client id
  --redirect-uri: string # Redirect uri
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/send-verify-email") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"client_id": $client_id, "redirect_uri": $redirect_uri} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<clients: record, id: string, ipAddress: string, lastAccess: int, start: int, userId: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($realm | is-empty) { error make --unspanned { msg: "path parameter 'realm' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({realm: (encode-path-segment $realm), id: (encode-path-segment $id)} | format pattern "/{realm}/users/{id}/sessions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
